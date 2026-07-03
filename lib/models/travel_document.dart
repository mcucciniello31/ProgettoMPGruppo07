class TravelDocument {
  final int? id;
  final int tripId;
  final String title;
  final String documentType; // Tipo di documento: 'Volo', 'Treno', 'Hotel', 'Attrazione', 'Altro'
  final String? bookingCode;
  final String? seat;
  final String? gate;
  final DateTime? dateTime;
  final String? notes;

  TravelDocument({
    this.id,
    required this.tripId,
    required this.title,
    required this.documentType,
    this.bookingCode,
    this.seat,
    this.gate,
    this.dateTime,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'documentType': documentType,
      'bookingCode': bookingCode,
      'seat': seat,
      'gate': gate,
      'dateTime': dateTime?.toIso8601String(),
      'notes': notes,
    };
  }

  factory TravelDocument.fromMap(Map<String, dynamic> map) {
    return TravelDocument(
      id: map['id'] as int?,
      tripId: map['tripId'] as int,
      title: map['title'] as String? ?? '',
      documentType: map['documentType'] as String? ?? 'Altro',
      bookingCode: map['bookingCode'] as String?,
      seat: map['seat'] as String?,
      gate: map['gate'] as String?,
      dateTime: map['dateTime'] != null ? DateTime.tryParse(map['dateTime'] as String) : null,
      notes: map['notes'] as String? ?? '',
    );
  }

  TravelDocument copyWith({
    int? id,
    int? tripId,
    String? title,
    String? documentType,
    String? bookingCode,
    String? seat,
    String? gate,
    DateTime? dateTime,
    String? notes,
  }) {
    return TravelDocument(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      documentType: documentType ?? this.documentType,
      bookingCode: bookingCode ?? this.bookingCode,
      seat: seat ?? this.seat,
      gate: gate ?? this.gate,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
    );
  }
}
