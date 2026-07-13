class Expense {
  final int? id;
  final int tripId;
  final String title;
  final double amount;
  final String
  category; // es: Trasporto, Alloggio, Cibo, Attività, Shopping, Altro
  final DateTime date;
  final String
  associatedType; // Tipo di associazione: 'Tappa', 'Attivita', 'Generale'
  final int? associatedId;
  final String
  associatedName; // es: nome della tappa, nome dell'attività, o 'Generale'
  final String
  paymentMethod; // es: Contanti, Carta di Credito, Carta di Debito, Apple Pay, Google Pay, Altro
  final String status; // Stato della spesa: 'Prevista', 'Sostenuta'
  final String notes;
  final String currency;

  Expense({
    this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.associatedType = 'Generale',
    this.associatedId,
    this.associatedName = 'Generale',
    this.paymentMethod = 'Contanti',
    this.status = 'Sostenuta',
    this.notes = '',
    this.currency = 'EUR',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'associatedType': associatedType,
      'associatedId': associatedId,
      'associatedName': associatedName,
      'paymentMethod': paymentMethod,
      'status': status,
      'notes': notes,
      'currency': currency,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      tripId: map['tripId'] as int,
      title: map['title'] as String? ?? map['description'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      associatedType: map['associatedType'] as String? ?? 'Generale',
      associatedId: map['associatedId'] as int?,
      associatedName: map['associatedName'] as String? ?? 'Generale',
      paymentMethod: map['paymentMethod'] as String? ?? 'Contanti',
      status: map['status'] as String? ?? 'Sostenuta',
      notes: map['notes'] as String? ?? '',
      currency: map['currency'] as String? ?? 'EUR',
    );
  }

  Expense copyWith({
    int? id,
    int? tripId,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? associatedType,
    int? associatedId,
    String? associatedName,
    String? paymentMethod,
    String? status,
    String? notes,
    String? currency,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      associatedType: associatedType ?? this.associatedType,
      associatedId: associatedId ?? this.associatedId,
      associatedName: associatedName ?? this.associatedName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
    );
  }
}
