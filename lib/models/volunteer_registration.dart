/// Represents a volunteer registration / application to an opportunity.
class VolunteerRegistration {
  final String id;
  final String opportunityId;
  final String volunteerId;
  final String volunteerName;
  final String volunteerEmail;
  final String opportunityTitle;
  String status; // 'joined', 'completed', 'cancelled'
  final String registeredAt;

  VolunteerRegistration({
    required this.id,
    required this.opportunityId,
    required this.volunteerId,
    required this.volunteerName,
    required this.volunteerEmail,
    required this.opportunityTitle,
    this.status = 'joined',
    required this.registeredAt,
  });

  bool get isJoined => status == 'joined';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  Map<String, dynamic> toJson() => {
        'id': id,
        'opportunityId': opportunityId,
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'volunteerEmail': volunteerEmail,
        'opportunityTitle': opportunityTitle,
        'status': status,
        'registeredAt': registeredAt,
      };

  factory VolunteerRegistration.fromJson(Map<String, dynamic> json) {
    return VolunteerRegistration(
      id: json['id'] as String,
      opportunityId: json['opportunityId'] as String,
      volunteerId: json['volunteerId'] as String,
      volunteerName: json['volunteerName'] as String? ?? 'Volunteer',
      volunteerEmail: json['volunteerEmail'] as String? ?? '',
      opportunityTitle: json['opportunityTitle'] as String? ?? '',
      status: json['status'] as String? ?? 'joined',
      registeredAt: json['registeredAt'] as String? ?? '',
    );
  }
}
