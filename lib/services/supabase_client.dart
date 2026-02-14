import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static const String supabaseUrl = 'https://kclmxzyoyaltgutgsjco.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjbG14enlveWFsdGd1dGdzamNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyMTYzMzcsImV4cCI6MjA3ODc5MjMzN30.GpJ2IjD5vNwYQll8apQCEaWn-1r_3FNfxw3GlMjBVf0';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
