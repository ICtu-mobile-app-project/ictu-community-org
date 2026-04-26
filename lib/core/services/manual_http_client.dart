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
    final baseUrl = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');
    
    // Construct the Edge Function URL manually
    final uri = Uri.parse('$baseUrl/functions/v1/$functionName');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
        'apikey': anonKey,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Request failed with status: ${response.statusCode}, body: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
