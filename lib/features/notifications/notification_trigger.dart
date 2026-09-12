import 'package:supabase_flutter/supabase_flutter.dart';

/// Fires one of the 4 supported notification types by calling the
/// `send-notification` Edge Function — every actual decision (who to
/// notify, the real title/body copy, the payment threshold/dedup rules)
/// lives server-side there, using real DB data, never anything computed
/// or trusted from this client. Called right after the triggering action
/// itself has already succeeded (placing an order, accepting one,
/// generating an invoice), so a failure here must never look like that
/// action failed — always fire-and-forget.
Future<void> triggerNotification(SupabaseClient client, {required String type, required String orderId}) async {
  try {
    await client.functions.invoke('send-notification', body: {'type': type, 'order_id': orderId});
  } catch (_) {
    // Deliberately swallowed — see doc comment above.
  }
}
