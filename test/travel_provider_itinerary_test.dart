import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:say_my_travel/models/stop.dart';
import 'package:say_my_travel/models/trip.dart';
import 'package:say_my_travel/providers/travel_provider.dart';
import 'package:say_my_travel/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    // Force a fresh in-memory-backed DB per test by resetting the singleton's
    // cached database so each test starts clean.
    DatabaseHelper.instance.resetDatabaseForTest();
  });

  test('addStop computes itineraryOrder from the stop date, not the input value', () async {
    final provider = TravelProvider();
    final trip = Trip(
      title: 'Parigi',
      destination: 'Parigi',
      startDate: DateTime(2026, 7, 10),
      endDate: DateTime(2026, 7, 12),
    );
    final insertedTrip = await DatabaseHelper.instance.insertTrip(trip);
    final tripId = insertedTrip.id!;
    await provider.loadTrips();
    await provider.selectTrip(provider.trips.firstWhere((t) => t.id == tripId));

    // Two stops on day 2 (2026-07-11), passing a bogus itineraryOrder of 99.
    await provider.addStop(Stop(
      tripId: tripId,
      name: 'Tappa A',
      description: 'desc',
      dateTime: DateTime(2026, 7, 11, 9, 0),
      location: 'Loc A',
      itineraryOrder: 99,
    ));
    await provider.addStop(Stop(
      tripId: tripId,
      name: 'Tappa B',
      description: 'desc',
      dateTime: DateTime(2026, 7, 11, 15, 0),
      location: 'Loc B',
      itineraryOrder: 99,
    ));

    final stops = provider.currentStops;
    expect(stops.length, 2);
    expect(stops.every((s) => s.itineraryOrder == 2), isTrue,
        reason: 'Both stops fall on day 2 of the trip and must share itineraryOrder 2');
  });
}
