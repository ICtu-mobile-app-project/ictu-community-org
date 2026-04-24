import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static String get _url => dotenv.get('SUPABASE_URL', fallback: '');
  static String get _anonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint(
          'Supabase is not configured. Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in your .env file.',
        );
      }
      return;
    }

    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );
  }
}
