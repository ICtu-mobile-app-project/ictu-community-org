import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint(
          'Supabase is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
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

