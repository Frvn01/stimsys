import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://iufncmylkytcgofecpkn.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_RVkiXa2N01jrhlIvXqs7jw_YzqEuCuE';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
