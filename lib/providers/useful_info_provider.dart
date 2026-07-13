part of 'travel_provider.dart';

extension UsefulInfoProvider on TravelProvider {

  // OPERAZIONI SU INFO UTILI

  Future<void> addUsefulInfo(UsefulInfo info) async {
    await _dbHelper.insertUsefulInfo(info);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> updateUsefulInfo(UsefulInfo info) async {
    await _dbHelper.updateUsefulInfo(info);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> deleteUsefulInfo(int id) async {
    await _dbHelper.deleteUsefulInfo(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }


  // OPERAZIONI SUI DOCUMENTI DI VIAGGIO

  Future<void> addTravelDocument(TravelDocument doc) async {
    await _dbHelper.insertTravelDocument(doc);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> updateTravelDocument(TravelDocument doc) async {
    await _dbHelper.updateTravelDocument(doc);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> deleteTravelDocument(int id) async {
    await _dbHelper.deleteTravelDocument(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }
}
