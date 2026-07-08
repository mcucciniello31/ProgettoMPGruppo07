import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:say_my_travel/models/diary_entry.dart';
import 'package:say_my_travel/models/stop.dart';
import 'package:say_my_travel/models/activity.dart';
import 'package:say_my_travel/models/trip.dart';
import 'package:say_my_travel/providers/travel_provider.dart';
import 'package:say_my_travel/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    DatabaseHelper.instance.resetDatabaseForTest();
  });

  test('DiaryEntry can be associated with a Stop or an Activity and correctly saved', () async {
    final provider = TravelProvider();
    final trip = Trip(
      title: 'Rome Adventure',
      destination: 'Rome',
      startDate: DateTime(2026, 7, 10),
      endDate: DateTime(2026, 7, 12),
    );
    final insertedTrip = await DatabaseHelper.instance.insertTrip(trip);
    final tripId = insertedTrip.id!;
    await provider.loadTrips();
    await provider.selectTrip(provider.trips.firstWhere((t) => t.id == tripId));

    // 1. Add a Stop
    final stop = Stop(
      tripId: tripId,
      name: 'Colosseum',
      description: 'Historical tour',
      dateTime: DateTime(2026, 7, 10, 10, 0),
      location: 'Rome, Italy',
      itineraryOrder: 1,
    );
    await provider.addStop(stop);
    final colosseumStop = provider.currentStops.first;

    // 2. Add an Activity to that stop
    final activity = Activity(
      stopId: colosseumStop.id!,
      name: 'Gladiator Entrance Tour',
      description: 'Tour of underground arena',
      time: '10:30',
      type: 'Visita',
      cost: 25.0,
      location: 'Colosseum Underground',
    );
    await provider.addActivity(activity);
    final activities = provider.getActivitiesForStop(colosseumStop.id!);
    final gladiatorActivity = activities.first;

    // 3. Add associated Diary Entry (to Stop)
    final stopMemory = DiaryEntry(
      tripId: tripId,
      title: 'Amazing Colosseum Visit',
      content: 'We saw the Colosseum, it was grand.',
      date: DateTime(2026, 7, 10),
      associatedType: 'Tappa',
      associatedId: colosseumStop.id,
      associatedName: colosseumStop.name,
    );
    await provider.addDiaryEntry(stopMemory);

    // 4. Add associated Diary Entry (to Activity)
    final activityMemory = DiaryEntry(
      tripId: tripId,
      title: 'Felt like a Gladiator',
      content: 'Walking through the underground arena was thrilling.',
      date: DateTime(2026, 7, 10),
      associatedType: 'Attivita',
      associatedId: gladiatorActivity.id,
      associatedName: gladiatorActivity.name,
    );
    await provider.addDiaryEntry(activityMemory);

    // 5. Verify they are in currentDiaryEntries with associations intact
    final entries = provider.currentDiaryEntries;
    expect(entries.length, 2);

    final retrievedStopMemory = entries.firstWhere((e) => e.title == 'Amazing Colosseum Visit');
    expect(retrievedStopMemory.associatedType, 'Tappa');
    expect(retrievedStopMemory.associatedId, colosseumStop.id);
    expect(retrievedStopMemory.associatedName, colosseumStop.name);

    final retrievedActivityMemory = entries.firstWhere((e) => e.title == 'Felt like a Gladiator');
    expect(retrievedActivityMemory.associatedType, 'Attivita');
    expect(retrievedActivityMemory.associatedId, gladiatorActivity.id);
    expect(retrievedActivityMemory.associatedName, gladiatorActivity.name);
  });
}
