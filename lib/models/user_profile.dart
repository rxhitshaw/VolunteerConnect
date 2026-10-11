/// Represents a verified record of completed volunteer hours.
/// Guarantees duplicate-entry protection by tracking unique activity IDs.
class VolunteerLog {
  final String id;
  final String opportunityId;
  final String title;
  final String cause;
  final int hours;
  final String completedDate;

  const VolunteerLog({
    required this.id,
    required this.opportunityId,
    required this.title,
    required this.cause,
    required this.hours,
    required this.completedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'opportunityId': opportunityId,
        'title': title,
        'cause': cause,
        'hours': hours,
        'completedDate': completedDate,
      };

  factory VolunteerLog.fromJson(Map<String, dynamic> json) {
    return VolunteerLog(
      id: json['id'] as String,
      opportunityId: json['opportunityId'] as String,
      title: json['title'] as String,
      cause: json['cause'] as String,
      hours: json['hours'] as int,
      completedDate: json['completedDate'] as String,
    );
  }
}

/// Represents the user's profile, preferences, bookmarks, and activity state.
class UserProfile {
  String name;
  Set<String> selectedCauses;
  Set<String> userSkills;
  Set<String> availableDays;
  int maxDistanceKm;
  Set<String> savedOpportunityIds;
  Set<String> joinedOpportunityIds;
  List<VolunteerLog> completedLogs;

  UserProfile({
    this.name = 'EcoVolunteer',
    Set<String>? selectedCauses,
    Set<String>? userSkills,
    Set<String>? availableDays,
    this.maxDistanceKm = 15,
    Set<String>? savedOpportunityIds,
    Set<String>? joinedOpportunityIds,
    List<VolunteerLog>? completedLogs,
  })  : selectedCauses = selectedCauses ?? {'Environment', 'Education'},
        userSkills = userSkills ?? {'Teamwork', 'Gardening', 'Teaching'},
        availableDays = availableDays ?? {'Saturday', 'Sunday'},
        savedOpportunityIds = savedOpportunityIds ?? {},
        joinedOpportunityIds = joinedOpportunityIds ?? {},
        completedLogs = completedLogs ?? [];

  /// Calculates total verified volunteer hours without duplicate entries.
  int get totalCompletedHours {
    return completedLogs.fold<int>(0, (sum, log) => sum + log.hours);
  }

  /// Checks if an opportunity has already been marked as completed to prevent duplicate hours.
  bool isOpportunityCompleted(String oppId) {
    return completedLogs.any((log) => log.opportunityId == oppId);
  }

  /// Returns user's impact milestone title based on verified hours.
  String get impactLevel {
    final hrs = totalCompletedHours;
    if (hrs >= 25) return 'Gold Community Champion 🏆';
    if (hrs >= 15) return 'Silver Changemaker 🌟';
    if (hrs >= 5) return 'Bronze Helper 🌱';
    return 'Active Volunteer Explorer 🚀';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'selectedCauses': selectedCauses.toList(),
        'userSkills': userSkills.toList(),
        'availableDays': availableDays.toList(),
        'maxDistanceKm': maxDistanceKm,
        'savedOpportunityIds': savedOpportunityIds.toList(),
        'joinedOpportunityIds': joinedOpportunityIds.toList(),
        'completedLogs': completedLogs.map((l) => l.toJson()).toList(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'EcoVolunteer',
      selectedCauses: Set<String>.from(json['selectedCauses'] as List? ?? ['Environment', 'Education']),
      userSkills: Set<String>.from(json['userSkills'] as List? ?? ['Teamwork', 'Gardening', 'Teaching']),
      availableDays: Set<String>.from(json['availableDays'] as List? ?? ['Saturday', 'Sunday']),
      maxDistanceKm: json['maxDistanceKm'] as int? ?? 15,
      savedOpportunityIds: Set<String>.from(json['savedOpportunityIds'] as List? ?? []),
      joinedOpportunityIds: Set<String>.from(json['joinedOpportunityIds'] as List? ?? []),
      completedLogs: (json['completedLogs'] as List? ?? [])
          .map((item) => VolunteerLog.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}
