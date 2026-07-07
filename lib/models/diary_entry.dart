class DiaryEntry {
  final int? id;
  final int tripId;
  final String title;
  final String content;
  final DateTime date;
  final String? imagePath;
  final String associatedType; // 'Generale', 'Tappa', 'Attivita'
  final int? associatedId; // ID della tappa o attività associata
  final String associatedName; // Nome della tappa/attività, o 'Generale'

  DiaryEntry({
    this.id,
    required this.tripId,
    required this.title,
    required this.content,
    required this.date,
    this.imagePath,
    this.associatedType = 'Generale',
    this.associatedId,
    this.associatedName = 'Generale',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'associatedType': associatedType,
      'associatedId': associatedId,
      'associatedName': associatedName,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      tripId: map['tripId'] as int,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      imagePath: map['imagePath'] as String?,
      associatedType: map['associatedType'] as String? ?? 'Generale',
      associatedId: map['associatedId'] as int?,
      associatedName: map['associatedName'] as String? ?? 'Generale',
    );
  }

  DiaryEntry copyWith({
    int? id,
    int? tripId,
    String? title,
    String? content,
    DateTime? date,
    String? imagePath,
    String? associatedType,
    int? associatedId,
    String? associatedName,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      associatedType: associatedType ?? this.associatedType,
      associatedId: associatedId ?? this.associatedId,
      associatedName: associatedName ?? this.associatedName,
    );
  }
}
