import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  static String get appUrl {
    final value = dotenv.env['APP_URL']?.trim() ?? 'https://memorymaker.com';
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static bool get demoMode {
    final value = dotenv.env['DEMO_MODE']?.toLowerCase().trim();
    return value == 'true' || supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
  }

  static Uri api(String path) => Uri.parse('$appUrl$path');
}
