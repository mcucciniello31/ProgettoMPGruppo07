part of 'travel_provider.dart';

extension ItineraryProvider on TravelProvider {
  // ==========================================
  // OPERAZIONI SULLE TAPPE
  // ==========================================

  int _dayNumberFor(Trip trip, DateTime dateTime) {
    final tripStartDay = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final stopDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return 1 + stopDay.difference(tripStartDay).inDays;
  }

  Future<Trip> _tripFor(int tripId) async {
    if (_selectedTrip != null && _selectedTrip!.id == tripId) {
      return _selectedTrip!;
    }
    final trip = await _dbHelper.getTrip(tripId);
    if (trip == null) {
      throw StateError('Trip $tripId not found while saving a stop');
    }
    return trip;
  }

  Future<void> addStop(Stop stop) async {
    final trip = await _tripFor(stop.tripId);
    final computedStop = stop.copyWith(
      itineraryOrder: _dayNumberFor(trip, stop.dateTime),
    );
    await _dbHelper.insertStop(computedStop);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> updateStop(Stop stop) async {
    final trip = await _tripFor(stop.tripId);
    final computedStop = stop.copyWith(
      itineraryOrder: _dayNumberFor(trip, stop.dateTime),
    );
    await _dbHelper.updateStop(computedStop);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> deleteStop(int id) async {
    if (_selectedTrip != null) {
      await _dbHelper.deleteStop(id);
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  // ==========================================
  // OPERAZIONI SULLE ATTIVITÀ
  // ==========================================

  Future<void> addActivity(Activity activity) async {
    await _dbHelper.insertActivity(activity);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> updateActivity(Activity activity) async {
    await _dbHelper.updateActivity(activity);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> deleteActivity(int id) async {
    await _dbHelper.deleteActivity(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }
}
