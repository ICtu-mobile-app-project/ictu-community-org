import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualHttpClient {
  static Future<Map<String, dynamic>> post(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final supabase = Supabase.instance.client;
    
    // Ensure we have a valid session before proceeding
    Session? session = supabase.auth.currentSession;
    
    if (session == null || session.isExpired) {
      // Attempt to refresh the session if it's expired or null
      final response = await supabase.auth.refreshSession();
      session = response.session;
    }

    if (session == null) {
      throw Exception('Authentication session not found. Please log in again.');
    }

    final baseUrl = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');
    
    // Construct the Edge Function URL manually
    final uri = Uri.parse('$baseUrl/functions/v1/$functionName');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': anonKey,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Request failed with status: ${response.statusCode}, body: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else {
      return {'data': decoded};
    }
  }
}
