import 'package:supabase_flutter/supabase_flutter.dart';

/// Shorthand accessor used throughout lib/data/repositories (the Business
/// Console admin app). Returns the same singleton client that main.dart
/// initializes via `Supabase.initialize(...)` at startup — this file does
/// not initialize or configure Supabase itself, so there is only ever one
/// client/session in the app.
SupabaseClient get supabase => Supabase.instance.client;
