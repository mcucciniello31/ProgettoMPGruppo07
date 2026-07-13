part of 'travel_provider.dart';

extension ChecklistProvider on TravelProvider {

  // OPERAZIONI SULLA CHECKLIST

  Future<void> addChecklistItem(ChecklistItem item) async {
    await _dbHelper.insertChecklistItem(item);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> toggleChecklistItem(ChecklistItem item) async {
    final updatedItem = item.copyWith(isChecked: !item.isChecked);
    await _dbHelper.updateChecklistItem(updatedItem);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> deleteChecklistItem(int id) async {
    await _dbHelper.deleteChecklistItem(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> updateChecklistItem(ChecklistItem item) async {
    await _dbHelper.updateChecklistItem(item);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }
}
