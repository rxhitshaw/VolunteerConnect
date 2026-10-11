import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Local data persistence service for VolunteerConnect.
/// Stores user preferences, bookmarks, joined activities, and completed hours logs
/// so that data survives app restarts without requiring an external backend.
class StorageService {
  static const String _profileKey = 'vc_user_profile_data_v1';

  // In-memory fallback if SharedPreferences encounters platform restrictions
  static UserProfile? _memoryCache;

  /// Loads the persisted user profile, or returns a default initialized profile.
  static Future<UserProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_profileKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        final profile = UserProfile.fromJson(decoded);
        _memoryCache = profile;
        return profile;
      }
    } catch (_) {
      // Return memory cache or fresh profile on any platform storage error
      if (_memoryCache != null) return _memoryCache!;
    }

    final fresh = UserProfile();
    _memoryCache = fresh;
    return fresh;
  }

  /// Saves the user profile to local persistent storage.
  static Future<bool> saveProfile(UserProfile profile) async {
    _memoryCache = profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(profile.toJson());
      return await prefs.setString(_profileKey, jsonStr);
    } catch (_) {
      // Memory state still preserved
      return false;
    }
  }

  /// Clears stored profile data to reset demo state.
  static Future<bool> clearProfile() async {
    _memoryCache = UserProfile();
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_profileKey);
    } catch (_) {
      return false;
    }
  }
}
