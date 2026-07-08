part of 'travel_provider.dart';

extension DiaryProvider on TravelProvider {
  // ==========================================
  // OPERAZIONI SUL DIARIO DI BORDO (RICORDI)
  // ==========================================

  Future<void> addDiaryEntry(DiaryEntry entry) async {
    await _dbHelper.insertDiaryEntry(entry);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    await _dbHelper.updateDiaryEntry(entry);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> deleteDiaryEntry(int id) async {
    await _dbHelper.deleteDiaryEntry(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }
}
