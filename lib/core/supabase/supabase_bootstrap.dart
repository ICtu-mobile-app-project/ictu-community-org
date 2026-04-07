import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static const String _defaultUrl =
      'https://grlrrdaarzczjnqdeahh.supabase.co';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdybHJyZGFhcnpjempucWRlYWhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2NTc1NTUsImV4cCI6MjA4OTIzMzU1NX0.a0M0rzjsEDaJv2MHk73NCBJgFCETjpMHtioSuqv53v8';

  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );
  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultAnonKey,
  );

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

