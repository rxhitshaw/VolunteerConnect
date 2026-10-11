/// Represents a volunteer opportunity in VolunteerConnect.
class Opportunity {
  final String id;
  final String title;
  final String cause;
  final String location;
  final String date;
  final String time;
  final String dayOfWeek; // e.g. 'Saturday', 'Sunday'
  final int hours;
  final int distanceKm;
  final int spotsTotal;
  final int spotsFilled;
  final String description;
  final List<String> requiredSkills;
  final String organizer;
  final bool isSample; // Clearly identifies sample event

  const Opportunity({
    required this.id,
    required this.title,
    required this.cause,
    required this.location,
    required this.date,
    required this.time,
    required this.dayOfWeek,
    required this.hours,
    required this.distanceKm,
    required this.spotsTotal,
    required this.spotsFilled,
    required this.description,
    required this.requiredSkills,
    required this.organizer,
    this.isSample = true,
  });

  int get spotsRemaining => (spotsTotal - spotsFilled).clamp(0, spotsTotal);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cause': cause,
        'location': location,
        'date': date,
        'time': time,
        'dayOfWeek': dayOfWeek,
        'hours': hours,
        'distanceKm': distanceKm,
        'spotsTotal': spotsTotal,
        'spotsFilled': spotsFilled,
        'description': description,
        'requiredSkills': requiredSkills,
        'organizer': organizer,
        'isSample': isSample,
      };

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] as String,
      title: json['title'] as String,
      cause: json['cause'] as String,
      location: json['location'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      hours: json['hours'] as int,
      distanceKm: json['distanceKm'] as int,
      spotsTotal: json['spotsTotal'] as int,
      spotsFilled: json['spotsFilled'] as int,
      description: json['description'] as String,
      requiredSkills: List<String>.from(json['requiredSkills'] as List),
      organizer: json['organizer'] as String,
      isSample: json['isSample'] as bool? ?? true,
    );
  }
}
