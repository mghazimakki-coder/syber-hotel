import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  static Session? get currentSession => _client.auth.currentSession;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );
      return response;
    } on AuthException catch (error) {
      if (kDebugMode) {
        debugPrint('SUPABASE AUTH ERROR');
        debugPrint('message: ${error.message}');
        debugPrint('statusCode: ${error.statusCode}');
        debugPrint('code: ${error.code}');
      }
      rethrow;
    }
  }

  static Future<void> signOut() => _client.auth.signOut();
}
