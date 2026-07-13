class UsefulInfo {
  final int? id;
  final int tripId;
  final String title;
  final String content;
  final String
  category; // Categoria delle info utili: 'Nota', 'Promemoria', 'Prenotazione', 'Indirizzo', 'Altro'

  UsefulInfo({
    this.id,
    required this.tripId,
    required this.title,
    required this.content,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'content': content,
      'category': category,
    };
  }

  factory UsefulInfo.fromMap(Map<String, dynamic> map) {
    return UsefulInfo(
      id: map['id'] as int?,
      tripId: map['tripId'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
    );
  }

  UsefulInfo copyWith({
    int? id,
    int? tripId,
    String? title,
    String? content,
    String? category,
  }) {
    return UsefulInfo(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
    );
  }
}
