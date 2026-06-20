class Trip {
  final int? id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImagePath;
  final double budget;
  final String status; // 'futuro', 'in_corso', 'completato', 'archiviato'
  final String participants; // list of names separated by comma
  final String generalInfo; // general notes
  final double? latitude; // main destination latitude
  final double? longitude; // main destination longitude

  Trip({
    this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.coverImagePath,
    this.budget = 0.0,
    this.status = 'futuro',
    this.participants = '',
    this.generalInfo = '',
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'coverImagePath': coverImagePath,
      'budget': budget,
      'status': status,
      'participants': participants,
      'generalInfo': generalInfo,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      title: map['title'] as String,
      destination: map['destination'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      coverImagePath: map['coverImagePath'] as String?,
      budget: (map['budget'] as num).toDouble(),
      status: map['status'] as String? ?? 'futuro',
      participants: map['participants'] as String? ?? '',
      generalInfo: map['generalInfo'] as String? ?? '',
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  Trip copyWith({
    int? id,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImagePath,
    double? budget,
    String? status,
    String? participants,
    String? generalInfo,
    double? latitude,
    double? longitude,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      generalInfo: generalInfo ?? this.generalInfo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
