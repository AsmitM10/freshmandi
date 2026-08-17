// Creates a Razorpay order for an existing invoice and stores the
// razorpay_order_id on it, so the Flutter client can open Razorpay
// Checkout with a server-issued order rather than a client-guessed
// amount (Razorpay requires this — an order must be created with your
// secret key before Checkout can charge against it).
//
// Ownership is enforced by using the CALLER's own JWT (not the service
// role) to read the invoice — RLS's existing `invoices_select_own` policy
// means this returns nothing if the invoice doesn't belong to the caller,
// with no extra ownership-check code needed here. The service-role client
// is only reached after that check passes, and only to store the
// razorpay_order_id (invoices still has zero authenticated write policy).
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { orderId } = await req.json();
    if (!orderId) {
      return json({ error: 'orderId is required' }, 400);
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return json({ error: 'Missing Authorization header' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const razorpayKeyId = Deno.env.get('RAZORPAY_KEY_ID')!;
    const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET')!;

    // Caller-scoped client — RLS-enforced, proves ownership by construction.
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: invoice, error: invoiceError } = await callerClient
      .from('invoices')
      .select('id, order_id, total_amount, payment_status, razorpay_order_id')
      .eq('order_id', orderId)
      .single();

    if (invoiceError || !invoice) {
      return json({ error: 'Invoice not found for this order' }, 404);
    }
    if (invoice.payment_status === 'paid') {
      return json({ error: 'This invoice is already paid' }, 400);
    }

    // Razorpay order amounts are in the smallest currency unit (paise).
    const amountPaise = Math.round(Number(invoice.total_amount) * 100);

    const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${btoa(`${razorpayKeyId}:${razorpayKeySecret}`)}`,
      },
      body: JSON.stringify({
        amount: amountPaise,
        currency: 'INR',
        receipt: orderId,
        payment_capture: 1,
      }),
    });

    if (!razorpayResponse.ok) {
      const detail = await razorpayResponse.text();
      console.error('Razorpay order creation failed:', detail);
      return json({ error: 'Could not create payment order' }, 502);
    }

    const razorpayOrder = await razorpayResponse.json();

    // Service-role only for this one write — invoices has no authenticated
    // write policy by design (see the orders-history migration).
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);
    const { error: updateError } = await serviceClient
      .from('invoices')
      .update({ razorpay_order_id: razorpayOrder.id })
      .eq('id', invoice.id);

    if (updateError) {
      console.error('Failed to store razorpay_order_id:', updateError);
      return json({ error: 'Could not prepare payment' }, 500);
    }

    return json({
      razorpayOrderId: razorpayOrder.id,
      amount: amountPaise,
      currency: 'INR',
      keyId: razorpayKeyId,
    });
  } catch (error) {
    console.error('create-razorpay-order error:', error);
    return json({ error: 'Unexpected error' }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
