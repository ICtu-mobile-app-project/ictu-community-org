import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ictu_community_org/core/supabase/supabase_bootstrap.dart';

class ProfileController extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? profileData;

  Future<void> loadProfile() async {
    if (!SupabaseBootstrap.isConfigured) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        error = 'User not logged in';
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      profileData = data;
      // Add email from auth user as it might not be in the profiles table depending on schema
      if (profileData != null && !profileData!.containsKey('email')) {
        profileData!['email'] = user.email;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
