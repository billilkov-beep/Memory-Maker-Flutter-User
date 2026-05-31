import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'demo_repository.dart';
import 'memorymaker_repository.dart';
import 'supabase_repository.dart';

class RepositoryProvider {
  static late MemoryMakerRepository instance;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    if (!AppConfig.demoMode) {
      await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
      instance = SupabaseRepository();
    } else {
      instance = DemoRepository();
    }
  }
}
