// Verifies a Razorpay Checkout payment server-side and marks the invoice
// paid. The client's claim that a payment succeeded is never trusted on
// its own — Razorpay's signature (HMAC-SHA256 of "order_id|payment_id"
// using your secret key) is the actual proof, recomputed here and
// compared before anything is written. This is the only place
// invoices.payment_status ever changes to 'paid'.
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = await req.json();
    if (!orderId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return json({ error: 'Missing required fields' }, 400);
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return json({ error: 'Missing Authorization header' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET')!;

    const expectedSignature = await hmacSha256Hex(razorpayKeySecret, `${razorpayOrderId}|${razorpayPaymentId}`);
    if (!timingSafeEqual(expectedSignature, razorpaySignature)) {
      return json({ error: 'Invalid payment signature' }, 400);
    }

    // Caller-scoped client — RLS-enforced, proves ownership by construction,
    // and confirms this really is the order this payment was created for.
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: invoice, error: invoiceError } = await callerClient
      .from('invoices')
      .select('id, order_id, razorpay_order_id, payment_status')
      .eq('order_id', orderId)
      .single();

    if (invoiceError || !invoice) {
      return json({ error: 'Invoice not found for this order' }, 404);
    }
    if (invoice.razorpay_order_id !== razorpayOrderId) {
      return json({ error: 'Payment does not match this invoice' }, 400);
    }
    if (invoice.payment_status === 'paid') {
      return json({ success: true }); // already recorded, e.g. a retried call
    }

    const serviceClient = createClient(supabaseUrl, serviceRoleKey);
    const { error: updateError } = await serviceClient
      .from('invoices')
      .update({ payment_status: 'paid', razorpay_payment_id: razorpayPaymentId })
      .eq('id', invoice.id);

    if (updateError) {
      console.error('Failed to mark invoice paid:', updateError);
      return json({ error: 'Could not record payment' }, 500);
    }

    return json({ success: true });
  } catch (error) {
    console.error('verify-razorpay-payment error:', error);
    return json({ error: 'Unexpected error' }, 500);
  }
});

async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(message));
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
