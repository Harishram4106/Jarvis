import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_models.dart';
import 'repository_interfaces.dart';

/// Persists the user's profile in the Android Keystore.
class ProfileStore implements UserRepository {
  static const _key = 'jarvis_profile';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _default = UserProfile(
    name: 'User',
    tagline: 'Curious Learner',
    email: '',
  );

  UserProfile? _cache;

  @override
  Future<UserProfile> getProfile() async {
    if (_cache != null) return _cache!;
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      _cache = _default;
      return _cache!;
    }
    try {
      _cache = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _cache = _default;
    }
    return _cache!;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _cache = profile;
    await _storage.write(key: _key, value: jsonEncode(profile.toJson()));
  }
}
