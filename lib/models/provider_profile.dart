/// Detailed profile for an Opportunity Provider / Event Organizer.
class ProviderProfile {
  final String id; // Matches AppUser.id
  String organizationName;
  String contactPerson;
  String organizationType;
  String phone;
  String description;

  ProviderProfile({
    required this.id,
    required this.organizationName,
    required this.contactPerson,
    required this.organizationType,
    this.phone = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationName': organizationName,
        'contactPerson': contactPerson,
        'organizationType': organizationType,
        'phone': phone,
        'description': description,
      };

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id'] as String,
      organizationName: json['organizationName'] as String? ?? 'Community Organizer',
      contactPerson: json['contactPerson'] as String? ?? 'Organizer Contact',
      organizationType: json['organizationType'] as String? ?? 'NGO',
      phone: json['phone'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
