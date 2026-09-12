// Single Edge Function handling all 4 notification types this app
// supports (order_request, order_accepted, payment, invoice). Every
// Flutter call site (customer: placing an order; admin: accepting an
// order, generating an invoice) just does
//   supabase.functions.invoke('send-notification', body: { type, order_id })
// and this function does everything else: figures out who to notify,
// computes the actual title/body/amounts from real DB data (never
// trusting anything the client claims about pricing), applies the
// payment-reminder threshold + duplicate-prevention rules, writes the
// in-app `notifications` row, and sends the push via the FCM v1 API.
// Centralizing it here means the business rules exist in exactly one
// place, and the private key needed to send pushes never has to leave
// this secure server-side environment.
//
// Required secrets (set via the dashboard, never committed):
//   FIREBASE_SERVICE_ACCOUNT_JSON — see supabase/functions/README or the
//     original send-order-accepted-push function this one replaces.
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are provided automatically.

import { createClient } from 'jsr:@supabase/supabase-js@2';

// Required so the browser's CORS preflight (OPTIONS) succeeds and every
// actual response carries Access-Control-Allow-Origin — without this, a
// browser client (Flutter web) is blocked by CORS before the request ever
// reaches this function, while a server-side caller (the Supabase
// Dashboard's Test panel, or verify-razorpay-payment's own fetch) is
// unaffected, since CORS is a browser-enforced rule, not a server one.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

function base64url(input: Uint8Array | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let str = '';
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const contents = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const binary = atob(contents);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned));
  const jwt = `${unsigned}.${base64url(new Uint8Array(signature))}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!tokenRes.ok) throw new Error(`Token exchange failed: ${tokenRes.status} ${await tokenRes.text()}`);
  const { access_token } = await tokenRes.json();
  return access_token as string;
}

function formatInr(amount: number): string {
  return `₹${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(amount)}`;
}

async function sendPush(
  serviceAccount: ServiceAccount,
  accessToken: string,
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<number> {
  if (tokens.length === 0) return 0;
  const results = await Promise.allSettled(
    tokens.map((token) =>
      fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: { token, notification: { title, body }, data } }),
      })
    ),
  );
  return results.filter((r) => r.status === 'fulfilled' && r.value.ok).length;
}

const SUPPORTED_TYPES = ['order_request', 'order_accepted', 'payment', 'invoice'];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { type, order_id } = await req.json();
    if (!order_id || !SUPPORTED_TYPES.includes(type)) {
      return jsonResponse(
        { error: 'type must be one of ' + SUPPORTED_TYPES.join(', ') + ', order_id is required' },
        400,
      );
    }

    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    const { data: order, error: orderError } = await supabase
      .from('admin_orders_console')
      .select('order_number, customer_id, total, invoice_number, payment_status')
      .eq('id', order_id)
      .single();
    if (orderError || !order) throw new Error(`Order lookup failed: ${orderError?.message ?? 'not found'}`);

    const serviceAccount: ServiceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!);
    const accessToken = await getAccessToken(serviceAccount);

    async function notify(opts: {
      title: string;
      body: string;
      toAdmin?: boolean;
      amount?: number;
      paymentStatus?: 'pending' | 'paid';
      extraData?: Record<string, string>;
    }) {
      const toAdmin = opts.toAdmin ?? false;

      let tokenQuery = supabase.from('device_tokens').select('token');
      tokenQuery = toAdmin ? tokenQuery.eq('is_admin', true) : tokenQuery.eq('restaurant_id', order.customer_id);
      const { data: tokenRows } = await tokenQuery;
      const tokens = (tokenRows ?? []).map((r) => r.token as string);

      await supabase.from('notifications').insert({
        restaurant_id: toAdmin ? null : order.customer_id,
        to_admin: toAdmin,
        type,
        title: opts.title,
        message: opts.body,
        order_id,
        amount: opts.amount ?? null,
        payment_status: opts.paymentStatus ?? null,
      });

      const sent = await sendPush(serviceAccount, accessToken, tokens, opts.title, opts.body, {
        type,
        order_id: String(order_id),
        ...(opts.extraData ?? {}),
      });
      return { sent, total: tokens.length };
    }

    switch (type) {
      case 'order_request': {
        const result = await notify({
          title: 'New Order Request',
          body: `New order #${order.order_number} has been placed.`,
          toAdmin: true,
        });
        return jsonResponse(result);
      }

      case 'order_accepted': {
        const result = await notify({
          title: 'Order Accepted',
          body: `Your order #${order.order_number} has been accepted.`,
        });
        return jsonResponse(result);
      }

      case 'invoice': {
        // Only the FIRST time an invoice appears for this order — Add
        // Sale can regenerate/edit the same invoice multiple times, and
        // re-sending "Invoice Ready" on every edit would be noise. A
        // changed total on edit is instead what the 'payment' branch
        // below is for.
        const { count } = await supabase
          .from('notifications')
          .select('id', { count: 'exact', head: true })
          .eq('order_id', order_id)
          .eq('type', 'invoice');
        if ((count ?? 0) > 0) {
          return jsonResponse({ sent: 0, reason: 'invoice notification already sent for this order' });
        }
        const result = await notify({
          title: 'Invoice Ready',
          body: `Your invoice for order #${order.order_number} is ready.`,
          extraData: order.invoice_number ? { invoice_id: order.invoice_number } : {},
        });
        return jsonResponse(result);
      }

      case 'payment': {
        const totalAmount = Number(order.total ?? 0);
        if (totalAmount <= 0) {
          return jsonResponse({ sent: 0, reason: 'order has no invoiced total yet' });
        }

        // Two distinct payment paths in this app: a customer's own
        // Razorpay "Pay Now" always pays the FULL invoice at once (see
        // verify-razorpay-payment, which flips invoices.payment_status
        // straight to 'paid' — there's no partial-Razorpay-payment
        // concept), while an admin manually recording amounts received
        // (Add Sale's "Received" field) is the only genuinely
        // incremental/partial path, logged as money_transactions rows
        // tied to this order (ref_type='Order'). A 'paid' invoice means
        // fully paid regardless of what those rows individually sum to.
        let paidAmount: number;
        if (order.payment_status === 'paid') {
          paidAmount = totalAmount;
        } else {
          const { data: paymentRows } = await supabase
            .from('money_transactions')
            .select('amount')
            .eq('ref_type', 'Order')
            .eq('ref_id', order_id);
          paidAmount = (paymentRows ?? []).reduce((sum, r) => sum + Number(r.amount), 0);
        }
        const remainingAmount = Math.max(0, totalAmount - paidAmount);

        const { data: thresholdRow } = await supabase
          .from('admin_settings')
          .select('value')
          .eq('key', 'payment_reminder_threshold')
          .maybeSingle();
        const threshold = Number(thresholdRow?.value?.amount ?? 10000);

        const { data: intervalRow } = await supabase
          .from('admin_settings')
          .select('value')
          .eq('key', 'payment_reminder_interval_days')
          .maybeSingle();
        const intervalDays = Number(intervalRow?.value?.days ?? 1);

        const { data: lastNotification } = await supabase
          .from('notifications')
          .select('amount, payment_status, created_at')
          .eq('order_id', order_id)
          .eq('type', 'payment')
          .order('created_at', { ascending: false })
          .limit(1)
          .maybeSingle();

        const commonData = {
          total_amount: String(totalAmount),
          paid_amount: String(paidAmount),
          remaining_amount: String(remainingAmount),
        };

        if (remainingAmount <= 0) {
          if (lastNotification?.payment_status === 'paid') {
            return jsonResponse({ sent: 0, reason: 'payment-successful notification already sent' });
          }
          const result = await notify({
            title: 'Payment Successful',
            body: `Payment of ${formatInr(totalAmount)} has been received for order #${order.order_number}.`,
            amount: 0,
            paymentStatus: 'paid',
            extraData: commonData,
          });
          return jsonResponse(result);
        }

        if (remainingAmount < threshold) {
          return jsonResponse({ sent: 0, reason: 'remaining amount below reminder threshold' });
        }

        if (lastNotification && lastNotification.payment_status !== 'paid' && Number(lastNotification.amount) === remainingAmount) {
          const elapsedMs = Date.now() - new Date(lastNotification.created_at as string).getTime();
          const elapsedDays = elapsedMs / (1000 * 60 * 60 * 24);
          if (elapsedDays < intervalDays) {
            return jsonResponse({ sent: 0, reason: 'same balance already reminded within the configured interval' });
          }
        }

        const result = await notify({
          title: 'Payment Pending',
          body: `${formatInr(remainingAmount)} payment is pending for order #${order.order_number}.`,
          amount: remainingAmount,
          paymentStatus: 'pending',
          extraData: commonData,
        });
        return jsonResponse(result);
      }

      default:
        return jsonResponse({ error: 'unreachable' }, 400);
    }
  } catch (error) {
    console.error('send-notification error:', error);
    return jsonResponse({ error: String(error) }, 500);
  }
});
