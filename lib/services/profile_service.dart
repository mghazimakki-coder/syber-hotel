import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole {
  customer,
  receptionist,
  manager;

  static AppRole? fromDatabaseValue(String? value) => switch (value) {
    'customer' => AppRole.customer,
    'receptionist' => AppRole.receptionist,
    'manager' => AppRole.manager,
    _ => null,
  };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.hotelId,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String? role;
  final String? hotelId;

  AppRole? get appRole => AppRole.fromDatabaseValue(role);

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String?,
      hotelId: map['hotel_id'] as String?,
    );
  }
}

class ProfileService {
  ProfileService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<UserProfile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final profile = await _client
        .from('profiles')
        .select('id, full_name, phone, role, hotel_id')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) return null;
    return UserProfile.fromMap(profile);
  }
}
