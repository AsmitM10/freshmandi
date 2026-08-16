/// Key names read from the `.env` file via flutter_dotenv. Loaded and
/// consumed when Supabase is initialized in Phase C.
class EnvKeys {
  EnvKeys._();

  static const String supabaseUrl = 'SUPABASE_URL';
  static const String supabaseAnonKey = 'SUPABASE_ANON_KEY';
}
