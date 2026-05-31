import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String _dartDefineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _dartDefineSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _dartDefineAppUrl = String.fromEnvironment('APP_URL');
  static const String _dartDefineDemoMode = String.fromEnvironment('DEMO_MODE');

  static String _clean(String value) => value.trim().replaceAll(RegExp(r'/+$'), '');

  static String get supabaseUrl {
    final value = _dartDefineSupabaseUrl.isNotEmpty ? _dartDefineSupabaseUrl : (dotenv.env['SUPABASE_URL'] ?? '');
    return _clean(value);
  }

  static String get supabaseAnonKey {
    final value = _dartDefineSupabaseAnonKey.isNotEmpty ? _dartDefineSupabaseAnonKey : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');
    return value.trim();
  }

  static String get appUrl {
    final value = _dartDefineAppUrl.isNotEmpty ? _dartDefineAppUrl : (dotenv.env['APP_URL'] ?? 'https://memorymaker.com');
    return _clean(value);
  }

  static bool get demoMode {
    final value = (_dartDefineDemoMode.isNotEmpty ? _dartDefineDemoMode : (dotenv.env['DEMO_MODE'] ?? '')).toLowerCase().trim();
    return value == 'true' || supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
  }

  static Uri api(String path) => Uri.parse('$appUrl$path');
}
