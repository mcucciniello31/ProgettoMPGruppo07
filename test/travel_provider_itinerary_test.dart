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
    // Forza un database pulito in memoria per ciascun test resettando il database
    // memorizzato nel singleton, così ogni test inizia da zero.
    DatabaseHelper.instance.resetDatabaseForTest();
  });

  test(
    'addStop computes itineraryOrder from the stop date, not the input value',
    () async {
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
      await provider.selectTrip(
        provider.trips.firstWhere((t) => t.id == tripId),
      );

      // Due tappe nel giorno 2 (2026-07-11), passando un valore fittizio per itineraryOrder pari a 99.
      await provider.addStop(
        Stop(
          tripId: tripId,
          name: 'Tappa A',
          description: 'desc',
          dateTime: DateTime(2026, 7, 11, 9, 0),
          location: 'Loc A',
          itineraryOrder: 99,
        ),
      );
      await provider.addStop(
        Stop(
          tripId: tripId,
          name: 'Tappa B',
          description: 'desc',
          dateTime: DateTime(2026, 7, 11, 15, 0),
          location: 'Loc B',
          itineraryOrder: 99,
        ),
      );

      final stops = provider.currentStops;
      expect(stops.length, 2);
      expect(
        stops.every((s) => s.itineraryOrder == 2),
        isTrue,
        reason:
            'Entrambe le tappe cadono nel giorno 2 del viaggio e devono condividere itineraryOrder pari a 2',
      );
    },
  );
}
