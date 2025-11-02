import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://szeubqfesrrqnvgaebtl.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6ZXVicWZlc3JycW52Z2FlYnRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3NTU3MTksImV4cCI6MjA3NjMzMTcxOX0.gjGywtqbBq06g7jfxplGGz20iu7ZJ2YQG27tT9QKSAk';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
