enum UserRole {
  volunteer,
  provider;

  String toValue() => name;

  static UserRole fromValue(String value) {
    if (value == 'provider') return UserRole.provider;
    return UserRole.volunteer;
  }
}

/// Represents an authenticated user in the VolunteerConnect platform.
/// Strictly segregates Volunteer and Opportunity Provider roles.
class AppUser {
  final String id;
  final String email;
  final String passwordHash;
  final String name;
  final UserRole role;
  final String createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  bool get isVolunteer => role == UserRole.volunteer;
  bool get isProvider => role == UserRole.provider;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
        'name': name,
        'role': role.toValue(),
        'createdAt': createdAt,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      name: json['name'] as String,
      role: UserRole.fromValue(json['role'] as String? ?? 'volunteer'),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
