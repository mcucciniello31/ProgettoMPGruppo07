class Activity {
  final int? id;
  final int stopId;
  final String name;
  final String type; // Categoria dell'attività: Visita, Escursione, Prenotazione, Pasto, Spostamento, Evento, Momento Libero, Altro
  final String description;
  final String time; // Orario o fascia oraria dell'attività
  final double cost;
  final String location;
  final String status; // Stato dell'attività: 'Da svolgere', 'Completata', 'Annullata'
  final String notes;

  Activity({
    this.id,
    required this.stopId,
    required this.name,
    required this.type,
    required this.description,
    required this.time,
    required this.cost,
    required this.location,
    this.status = 'Da svolgere',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stopId': stopId,
      'name': name,
      'type': type,
      'description': description,
      'time': time,
      'cost': cost,
      'location': location,
      'status': status,
      'notes': notes,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      stopId: map['stopId'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      description: map['description'] as String? ?? '',
      time: map['time'] as String,
      cost: (map['cost'] as num).toDouble(),
      location: map['location'] as String? ?? '',
      status: map['status'] as String? ?? 'Da svolgere',
      notes: map['notes'] as String? ?? '',
    );
  }

  Activity copyWith({
    int? id,
    int? stopId,
    String? name,
    String? type,
    String? description,
    String? time,
    double? cost,
    String? location,
    String? status,
    String? notes,
  }) {
    return Activity(
      id: id ?? this.id,
      stopId: stopId ?? this.stopId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      time: time ?? this.time,
      cost: cost ?? this.cost,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
