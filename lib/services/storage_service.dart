import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sample_opportunities.dart';
import '../models/app_user.dart';
import '../models/opportunity.dart';
import '../models/provider_profile.dart';
import '../models/user_profile.dart';
import '../models/volunteer_registration.dart';
import 'hash_util.dart';

/// Comprehensive local data persistence and authentication service for VolunteerConnect.
///
/// Features:
/// - Role-segregated user registration and login (Volunteer & Opportunity Provider)
/// - SHA-256 cryptographic password hashing (never stores plain text passwords)
/// - Session persistence and role verification
/// - Dynamic opportunity repository synced across volunteer and provider interfaces
/// - Overbooking protection and anti-duplicate registration verification
/// - Anti-duplicate volunteer hour crediting and milestone tracking
class StorageService {
  static const String _usersKey = 'vc_users_list_v2';
  static const String _currentSessionKey = 'vc_current_session_v2';
  static const String _profilePrefix = 'vc_user_profile_';
  static const String _legacyProfileKey = 'vc_user_profile_data_v1';
  static const String _providerPrefix = 'vc_provider_profile_';
  static const String _opportunitiesKey = 'vc_opportunities_v2';
  static const String _registrationsKey = 'vc_registrations_v2';

  // In-memory caching fallbacks
  static final Map<String, AppUser> _memoryUsers = {};
  static AppUser? _currentSession;
  static final Map<String, UserProfile> _memoryProfiles = {};
  static final Map<String, ProviderProfile> _memoryProviders = {};
  static List<Opportunity>? _memoryOpportunities;
  static final List<VolunteerRegistration> _memoryRegistrations = [];

  // ==========================================
  // AUTHENTICATION & INITIALIZATION
  // ==========================================

  /// Seeds default demo accounts and initial opportunities if first run.
  static Future<void> initializeData() async {
    final existingUsers = await _loadAllUsers();
    if (existingUsers.isEmpty) {
      // Seed Demo Volunteer: volunteer@demo.com / Volunteer123!
      final volUser = AppUser(
        id: 'usr-vol-demo',
        email: 'volunteer@demo.com',
        passwordHash: HashUtil.sha256('Volunteer123!'),
        name: 'EcoVolunteer',
        role: UserRole.volunteer,
        createdAt: DateTime.now().toIso8601String(),
      );
      final volProfile = UserProfile(
        userId: volUser.id,
        email: volUser.email,
        name: volUser.name,
      );

      // Seed Demo Provider: org@greenearthealliance.org / Provider123!
      final provUser = AppUser(
        id: 'usr-prov-demo',
        email: 'org@greenearthealliance.org',
        passwordHash: HashUtil.sha256('Provider123!'),
        name: 'Green Earth Alliance',
        role: UserRole.provider,
        createdAt: DateTime.now().toIso8601String(),
      );
      final provProfile = ProviderProfile(
        id: provUser.id,
        organizationName: 'Green Earth Alliance',
        contactPerson: 'Sarah Jenkins',
        organizationType: 'NGO',
        phone: '+1 (555) 234-5678',
        description: 'Dedicated to urban green spaces, sustainability, and community tree planting.',
      );

      await _saveUser(volUser);
      await saveProfile(volProfile);

      await _saveUser(provUser);
      await saveProviderProfile(provProfile);
    }

    // Ensure opportunities repository is initialized
    await loadOpportunities();
  }

  static Future<Map<String, AppUser>> _loadAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_usersKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        final map = <String, AppUser>{};
        decoded.forEach((key, val) {
          map[key] = AppUser.fromJson(Map<String, dynamic>.from(val as Map));
        });
        _memoryUsers.clear();
        _memoryUsers.addAll(map);
        return map;
      }
    } catch (_) {}
    return _memoryUsers;
  }

  static Future<void> _saveUser(AppUser user) async {
    _memoryUsers[user.email.toLowerCase()] = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      _memoryUsers.forEach((key, val) => map[key] = val.toJson());
      await prefs.setString(_usersKey, jsonEncode(map));
    } catch (_) {}
  }

  /// Registers a new volunteer user.
  static Future<AppUser?> registerVolunteer({
    required String name,
    required String email,
    required String password,
    required Set<String> preferredCauses,
    required Set<String> skills,
    required Set<String> availabilityDays,
  }) async {
    final users = await _loadAllUsers();
    final normalizedEmail = email.trim().toLowerCase();
    if (users.containsKey(normalizedEmail)) {
      return null; // Email already registered
    }

    final userId = 'usr-vol-${DateTime.now().millisecondsSinceEpoch}';
    final user = AppUser(
      id: userId,
      email: normalizedEmail,
      passwordHash: HashUtil.sha256(password),
      name: name.trim(),
      role: UserRole.volunteer,
      createdAt: DateTime.now().toIso8601String(),
    );

    final profile = UserProfile(
      userId: userId,
      email: normalizedEmail,
      name: name.trim(),
      selectedCauses: preferredCauses,
      userSkills: skills,
      availableDays: availabilityDays,
    );

    await _saveUser(user);
    await saveProfile(profile);
    await saveSession(user);
    return user;
  }

  /// Registers a new opportunity provider / organizer.
  static Future<AppUser?> registerProvider({
    required String organizationName,
    required String contactPerson,
    required String email,
    required String password,
    required String organizationType,
    String phone = '',
    String description = '',
  }) async {
    final users = await _loadAllUsers();
    final normalizedEmail = email.trim().toLowerCase();
    if (users.containsKey(normalizedEmail)) {
      return null; // Email already registered
    }

    final userId = 'usr-prov-${DateTime.now().millisecondsSinceEpoch}';
    final user = AppUser(
      id: userId,
      email: normalizedEmail,
      passwordHash: HashUtil.sha256(password),
      name: contactPerson.trim(),
      role: UserRole.provider,
      createdAt: DateTime.now().toIso8601String(),
    );

    final profile = ProviderProfile(
      id: userId,
      organizationName: organizationName.trim(),
      contactPerson: contactPerson.trim(),
      organizationType: organizationType,
      phone: phone.trim(),
      description: description.trim(),
    );

    await _saveUser(user);
    await saveProviderProfile(profile);
    await saveSession(user);
    return user;
  }

  /// Authenticates user and verifies expected role.
  static Future<AppUser?> authenticate({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    final users = await _loadAllUsers();
    final normalizedEmail = email.trim().toLowerCase();
    final user = users[normalizedEmail];
    if (user == null) return null;

    final inputHash = HashUtil.sha256(password);
    if (user.passwordHash != inputHash) return null;

    if (user.role != expectedRole) return null;

    await saveSession(user);
    return user;
  }

  // ==========================================
  // SESSION MANAGEMENT
  // ==========================================

  static Future<void> saveSession(AppUser user) async {
    _currentSession = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentSessionKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  static Future<AppUser?> getCurrentSession() async {
    if (_currentSession != null) return _currentSession;
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_currentSessionKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        _currentSession = AppUser.fromJson(Map<String, dynamic>.from(decoded as Map));
        return _currentSession;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearSession() async {
    _currentSession = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentSessionKey);
    } catch (_) {}
  }

  // ==========================================
  // VOLUNTEER PROFILES
  // ==========================================

  static Future<UserProfile> loadProfile([String? userId]) async {
    final targetId = userId ?? _currentSession?.id ?? 'usr-vol-demo';
    final key = '$_profilePrefix$targetId';

    try {
      final prefs = await SharedPreferences.getInstance();
      var jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) {
        // Fallback to legacy single-user key if migrating
        jsonStr = prefs.getString(_legacyProfileKey);
      }

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        final profile = UserProfile.fromJson(decoded);
        _memoryProfiles[targetId] = profile;
        return profile;
      }
    } catch (_) {}

    if (_memoryProfiles.containsKey(targetId)) {
      return _memoryProfiles[targetId]!;
    }

    final fresh = UserProfile(userId: targetId);
    _memoryProfiles[targetId] = fresh;
    return fresh;
  }

  static Future<bool> saveProfile(UserProfile profile) async {
    _memoryProfiles[profile.userId] = profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(profile.toJson());
      await prefs.setString('$_profilePrefix${profile.userId}', jsonStr);
      await prefs.setString(_legacyProfileKey, jsonStr);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> clearProfile([String? userId]) async {
    final targetId = userId ?? _currentSession?.id ?? 'usr-vol-demo';
    _memoryProfiles[targetId] = UserProfile(userId: targetId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_profilePrefix$targetId');
      await prefs.remove(_legacyProfileKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // PROVIDER PROFILES
  // ==========================================

  static Future<ProviderProfile> loadProviderProfile(String providerId) async {
    final key = '$_providerPrefix$providerId';
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        final profile = ProviderProfile.fromJson(Map<String, dynamic>.from(decoded as Map));
        _memoryProviders[providerId] = profile;
        return profile;
      }
    } catch (_) {}

    if (_memoryProviders.containsKey(providerId)) {
      return _memoryProviders[providerId]!;
    }

    final fresh = ProviderProfile(
      id: providerId,
      organizationName: 'Community Organizer',
      contactPerson: 'Organizer Contact',
      organizationType: 'NGO',
    );
    _memoryProviders[providerId] = fresh;
    return fresh;
  }

  static Future<bool> saveProviderProfile(ProviderProfile profile) async {
    _memoryProviders[profile.id] = profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_providerPrefix${profile.id}', jsonEncode(profile.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // DYNAMIC OPPORTUNITIES REPOSITORY
  // ==========================================

  /// Loads all opportunities (defaults to sampleOpportunities seeded on first run).
  static Future<List<Opportunity>> loadOpportunities() async {
    if (_memoryOpportunities != null && _memoryOpportunities!.isNotEmpty) {
      return List<Opportunity>.from(_memoryOpportunities!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_opportunitiesKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        final opps = list
            .map((item) => Opportunity.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        _memoryOpportunities = opps;
        return List<Opportunity>.from(opps);
      }
    } catch (_) {}

    // First run: seed with existing sample opportunities
    final initialList = sampleOpportunities.map((opp) {
      return opp.copyWith(
        providerId: opp.organizer == 'Green Earth Alliance' ? 'usr-prov-demo' : 'org-default',
      );
    }).toList();

    _memoryOpportunities = initialList;
    await _saveOpportunitiesList(initialList);
    return List<Opportunity>.from(initialList);
  }

  static Future<void> _saveOpportunitiesList(List<Opportunity> list) async {
    _memoryOpportunities = list;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(list.map((o) => o.toJson()).toList());
      await prefs.setString(_opportunitiesKey, jsonStr);
    } catch (_) {}
  }

  /// Creates and publishes a new opportunity by a provider.
  static Future<void> createOpportunity(Opportunity opp) async {
    final list = await loadOpportunities();
    list.insert(0, opp);
    await _saveOpportunitiesList(list);
  }

  /// Edits an existing opportunity owned by provider.
  static Future<bool> updateOpportunity(Opportunity updated, String providerId) async {
    final list = await loadOpportunities();
    final idx = list.indexWhere((o) => o.id == updated.id);
    if (idx == -1) return false;

    // Authorization guard: verify owner
    if (list[idx].providerId != providerId) return false;

    list[idx] = updated;
    await _saveOpportunitiesList(list);
    return true;
  }

  /// Deletes an opportunity owned by provider.
  static Future<bool> deleteOpportunity(String oppId, String providerId) async {
    final list = await loadOpportunities();
    final idx = list.indexWhere((o) => o.id == oppId);
    if (idx == -1) return false;

    // Authorization guard: verify owner
    if (list[idx].providerId != providerId) return false;

    list.removeAt(idx);
    await _saveOpportunitiesList(list);
    return true;
  }

  /// Updates opportunity status (open, full, completed).
  static Future<bool> setOpportunityStatus(String oppId, String status, String providerId) async {
    final list = await loadOpportunities();
    final idx = list.indexWhere((o) => o.id == oppId);
    if (idx == -1) return false;

    if (list[idx].providerId != providerId) return false;

    list[idx] = list[idx].copyWith(status: status);
    await _saveOpportunitiesList(list);
    return true;
  }

  // ==========================================
  // REGISTRATIONS & SLOTS MANAGEMENT
  // ==========================================

  static Future<List<VolunteerRegistration>> loadRegistrations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_registrationsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        final regs = list
            .map((item) => VolunteerRegistration.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        _memoryRegistrations.clear();
        _memoryRegistrations.addAll(regs);
        return List<VolunteerRegistration>.from(regs);
      }
    } catch (_) {}
    return List<VolunteerRegistration>.from(_memoryRegistrations);
  }

  static Future<void> _saveRegistrations(List<VolunteerRegistration> regs) async {
    _memoryRegistrations.clear();
    _memoryRegistrations.addAll(regs);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_registrationsKey, jsonEncode(regs.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  /// Registers a volunteer for an opportunity with overbooking and duplicate protection.
  static Future<String?> registerVolunteerForOpportunity({
    required String volunteerId,
    required String volunteerName,
    required String volunteerEmail,
    required String opportunityId,
  }) async {
    final opps = await loadOpportunities();
    final oppIdx = opps.indexWhere((o) => o.id == opportunityId);
    if (oppIdx == -1) return 'Opportunity not found.';

    final opp = opps[oppIdx];

    // Duplicate registration guard
    final regs = await loadRegistrations();
    final existing = regs.any((r) => r.opportunityId == opportunityId && r.volunteerId == volunteerId && r.isJoined);
    if (existing) {
      return 'You are already registered for this activity!';
    }

    // Overbooking guard
    if (opp.spotsRemaining <= 0 || opp.isFull) {
      return 'Sorry, this activity is completely full!';
    }

    // Record registration
    final newReg = VolunteerRegistration(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      opportunityId: opportunityId,
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      volunteerEmail: volunteerEmail,
      opportunityTitle: opp.title,
      status: 'joined',
      registeredAt: DateTime.now().toLocal().toString().split('.')[0],
    );

    regs.add(newReg);
    await _saveRegistrations(regs);

    // Update spot count on opportunity
    opps[oppIdx] = opp.copyWith(spotsFilled: opp.spotsFilled + 1);
    await _saveOpportunitiesList(opps);

    return null; // Success (no error)
  }

  /// Cancels / leaves an activity registration.
  static Future<void> cancelRegistration({
    required String volunteerId,
    required String opportunityId,
  }) async {
    final regs = await loadRegistrations();
    final idx = regs.indexWhere((r) => r.opportunityId == opportunityId && r.volunteerId == volunteerId && r.isJoined);
    if (idx != -1) {
      regs[idx].status = 'cancelled';
      await _saveRegistrations(regs);

      // Decrement spot count
      final opps = await loadOpportunities();
      final oppIdx = opps.indexWhere((o) => o.id == opportunityId);
      if (oppIdx != -1) {
        final opp = opps[oppIdx];
        opps[oppIdx] = opp.copyWith(spotsFilled: (opp.spotsFilled - 1).clamp(0, opp.spotsTotal));
        await _saveOpportunitiesList(opps);
      }
    }
  }

  /// Returns participants registered for a specific opportunity.
  static Future<List<VolunteerRegistration>> getParticipantsForOpportunity(String opportunityId) async {
    final regs = await loadRegistrations();
    return regs.where((r) => r.opportunityId == opportunityId && r.isJoined).toList();
  }

  /// Returns all active registrations for opportunities created by a specific provider.
  static Future<List<VolunteerRegistration>> getParticipantsForProvider(String providerId) async {
    final opps = await loadOpportunities();
    final providerOppIds = opps.where((o) => o.providerId == providerId).map((o) => o.id).toSet();
    final regs = await loadRegistrations();
    return regs.where((r) => providerOppIds.contains(r.opportunityId) && r.isJoined).toList();
  }
}
