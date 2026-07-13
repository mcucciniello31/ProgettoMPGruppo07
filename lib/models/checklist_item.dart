class ChecklistItem {
  final int? id;
  final int tripId;
  final String itemText;
  final bool isChecked;
  final String
  category; // Categoria: 'Bagaglio', 'Documenti', 'Pre-partenza', 'Prenotazioni', 'Acquisti', 'Altro'
  final String priority; // Priorità dell'elemento: 'Bassa', 'Media', 'Alta'

  ChecklistItem({
    this.id,
    required this.tripId,
    required this.itemText,
    this.isChecked = false,
    this.category = 'Bagaglio',
    this.priority = 'Media',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'itemText': itemText,
      'isChecked': isChecked ? 1 : 0,
      'category': category,
      'priority': priority,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as int?,
      tripId: map['tripId'] as int,
      itemText: map['itemText'] as String,
      isChecked: (map['isChecked'] as int) == 1,
      category: map['category'] as String? ?? 'Bagaglio',
      priority: map['priority'] as String? ?? 'Media',
    );
  }

  ChecklistItem copyWith({
    int? id,
    int? tripId,
    String? itemText,
    bool? isChecked,
    String? category,
    String? priority,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      itemText: itemText ?? this.itemText,
      isChecked: isChecked ?? this.isChecked,
      category: category ?? this.category,
      priority: priority ?? this.priority,
    );
  }
}
