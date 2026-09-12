import 'package:flutter/material.dart';

/// Lets code with no BuildContext of its own (PushNotificationService's
/// foreground-message listener, which fires from an FCM callback, not a
/// widget build) show a SnackBar. Attached to MaterialApp.router in
/// main.dart.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
