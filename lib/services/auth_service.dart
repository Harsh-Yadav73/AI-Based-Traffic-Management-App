import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // SIGN UP
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) {
        return "Signup failed. Try again.";
      }

      // 🔥 Save OneSignal Player ID for this user
      await _savePlayerId(res.user!.id);

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // SIGN IN
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        return "Login failed. Check email/password.";
      }

      // 🔥 Save OneSignal Player ID again (in case device changed)
      await _savePlayerId(res.user!.id);

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // 🔥 Save OneSignal Player ID in Supabase database
  Future<void> _savePlayerId(String userId) async {
    final playerId = OneSignal.User.pushSubscription.id;

    if (playerId == null) return;

    await supabase.from('user_push_tokens').upsert(
      {
        'user_id': userId,
        'player_id': playerId,
      },
      onConflict: 'user_id', // ⭐ REQUIRED FIX
    );
  }
}

