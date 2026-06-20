class Stop {
  final int? id;
  final int tripId;
  final String name;
  final String description;
  final DateTime dateTime;
  final String location;
  final int itineraryOrder;
  final String notes;
  final double? latitude;
  final double? longitude;

  Stop({
    this.id,
    required this.tripId,
    required this.name,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.itineraryOrder,
    this.notes = '',
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'name': name,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'itineraryOrder': itineraryOrder,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      id: map['id'] as int?,
      tripId: map['tripId'] as int,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      dateTime: DateTime.parse(map['dateTime'] as String),
      location: map['location'] as String? ?? '',
      itineraryOrder: map['itineraryOrder'] as int? ?? 1,
      notes: map['notes'] as String? ?? '',
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  Stop copyWith({
    int? id,
    int? tripId,
    String? name,
    String? description,
    DateTime? dateTime,
    String? location,
    int? itineraryOrder,
    String? notes,
    double? latitude,
    double? longitude,
  }) {
    return Stop(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      itineraryOrder: itineraryOrder ?? this.itineraryOrder,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
