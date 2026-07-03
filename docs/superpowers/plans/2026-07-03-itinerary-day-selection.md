# Itinerary Day Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `Stop.itineraryOrder` reflect the stop's real calendar day (derived from `trip.startDate`) instead of a manually-typed number, so the "Giorno ${stop.itineraryOrder}" label in the itinerary UI is correct when multiple stops share the same day.

**Architecture:** `TravelProvider.addStop`/`updateStop` compute `itineraryOrder` from `stop.dateTime` vs. the trip's `startDate` before persisting, replacing the old manual shift/renumber logic (`_reorderStops`). `AddStopScreen` replaces the free date-picker + manual order text field with a closed dropdown of the trip's actual days plus the existing time picker.

**Tech Stack:** Flutter, Provider, sqflite (no schema change).

## Global Constraints

- No DB migration — `stops.itineraryOrder` column and its type are unchanged, only who computes the value changes.
- `DatabaseHelper.getStopsForTrip` ordering (`itineraryOrder ASC, dateTime ASC`, `database_helper.dart:363`) is unchanged.
- `Activity` model/screens are untouched — multiple activities per stop already work.
- UI copy stays in Italian, matching existing strings in `add_stop_screen.dart`.

---

### Task 1: Derive `itineraryOrder` from date in `TravelProvider`

**Files:**
- Modify: `lib/providers/travel_provider.dart:114-185`
- Test: `test/travel_provider_itinerary_test.dart` (create)

**Interfaces:**
- Consumes: `DatabaseHelper.getTrip(int id) -> Future<Trip?>` (`database_helper.dart:299`), `DatabaseHelper.getStopsForTrip(int tripId) -> Future<List<Stop>>`, `DatabaseHelper.insertStop`, `DatabaseHelper.updateStop`, `DatabaseHelper.deleteStop` (all pre-existing, unchanged signatures).
- Produces: `TravelProvider.addStop(Stop stop) -> Future<void>` and `TravelProvider.updateStop(Stop stop) -> Future<void>` now ignore the `itineraryOrder` passed in `stop` and instead persist a value computed as `dayNumberFor(trip, stop.dateTime)`, a private helper `int _dayNumberFor(Trip trip, DateTime dateTime)` computing `1 + DateTime(dateTime.year, dateTime.month, dateTime.day).difference(DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day)).inDays`. `deleteStop` no longer calls `_reorderStops`. Later tasks (`AddStopScreen`) rely on being able to pass any placeholder `itineraryOrder` (e.g. `1`) into `Stop(...)` when constructing a new/edited stop — the provider overwrites it.

This project currently has no test file for the provider (`test/widget_test.dart` is the only test, and is unrelated). This task creates the first one.

- [ ] **Step 1: Write the failing test**

Create `test/travel_provider_itinerary_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zefiro/models/stop.dart';
import 'package:zefiro/models/trip.dart';
import 'package:zefiro/providers/travel_provider.dart';
import 'package:zefiro/services/database_helper.dart';

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
```

This test needs `sqflite_common_ffi` (desktop/test-friendly sqflite backend) and a `DatabaseHelper.resetDatabaseForTest()` test hook, plus `TravelProvider.trips`/`selectTrip` accessors — check `lib/providers/travel_provider.dart` for the exact existing getter name for the trips list (it is `trips`, confirm by reading the top of the file) before relying on it verbatim.

- [ ] **Step 2: Add the `sqflite_common_ffi` dev dependency**

Run: `flutter pub add --dev sqflite_common_ffi`
Expected: `pubspec.yaml` gains a `sqflite_common_ffi: ^x.y.z` line under `dev_dependencies`.

- [ ] **Step 3: Add a test-only DB reset hook**

In `lib/services/database_helper.dart`, inside the `DatabaseHelper` class, add:

```dart
  @visibleForTesting
  Future<void> resetDatabaseForTest() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
    _database = null;
  }
```

Add `import 'package:flutter/foundation.dart';` at the top of `database_helper.dart` if `@visibleForTesting` is not already available (check existing imports first).

- [ ] **Step 4: Run the test to verify it fails**

Run: `flutter test test/travel_provider_itinerary_test.dart`
Expected: FAIL — `itineraryOrder` on both stops is `99`, or a compile error if `resetDatabaseForTest` isn't wired yet (fix compile errors first, then confirm the assertion itself fails on unmodified `addStop`).

- [ ] **Step 5: Implement `_dayNumberFor` and use it in `addStop`/`updateStop`; delete `_reorderStops`**

Replace `lib/providers/travel_provider.dart:114-185` (the `STOP OPERATIONS` section from `_reorderStops` through `deleteStop`) with:

```dart
  // ==========================================
  // STOP OPERATIONS
  // ==========================================

  int _dayNumberFor(Trip trip, DateTime dateTime) {
    final tripStartDay = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
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
    final computedStop = stop.copyWith(itineraryOrder: _dayNumberFor(trip, stop.dateTime));
    await _dbHelper.insertStop(computedStop);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> updateStop(Stop stop) async {
    final trip = await _tripFor(stop.tripId);
    final computedStop = stop.copyWith(itineraryOrder: _dayNumberFor(trip, stop.dateTime));
    await _dbHelper.updateStop(computedStop);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> deleteStop(int id) async {
    if (_selectedTrip != null) {
      await _dbHelper.deleteStop(id);
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/travel_provider_itinerary_test.dart`
Expected: PASS

- [ ] **Step 7: Run the full test suite to check nothing else broke**

Run: `flutter test`
Expected: All tests pass (including the pre-existing `test/widget_test.dart`).

- [ ] **Step 8: Commit**

```bash
git add lib/providers/travel_provider.dart lib/services/database_helper.dart pubspec.yaml pubspec.lock test/travel_provider_itinerary_test.dart
git commit -m "$(cat <<'EOF'
Derive Stop.itineraryOrder from date instead of manual reordering

Multiple stops on the same trip day now share the same itineraryOrder
(computed from trip.startDate), instead of getting distinct sequential
values from the old manual shift-and-renumber logic.
EOF
)"
```

---

### Task 2: Replace manual order field + free date picker with a day dropdown in `AddStopScreen`

**Files:**
- Modify: `lib/screens/add_stop_screen.dart`

**Interfaces:**
- Consumes: `TravelProvider.addStop`/`updateStop` from Task 1 (now itineraryOrder-agnostic — any value can be passed in `Stop.itineraryOrder`, it gets overwritten). `Trip.startDate`, `Trip.endDate` (existing fields).
- Produces: No new public interface — this is a leaf UI screen. Internal state renamed/added: `_selectedDayIndex` (int, 0-indexed day offset within the trip) replaces the day portion of `_stopDateTime`; `_stopTime` (`TimeOfDay`) replaces the time portion. `_stopDateTime` getter combines both when saving.

- [ ] **Step 1: Remove the manual order controller and its validation**

In `lib/screens/add_stop_screen.dart`, remove:
- The field declaration `late TextEditingController _itineraryOrderController;` (line 34).
- Its initialization in `initState` (lines 65-68: the `defaultOrder` computation and `_itineraryOrderController = TextEditingController(...)`).
- Its disposal in `dispose()` (line 108: `_itineraryOrderController.dispose();`).
- The whole `orderText`/order validation block in `_save()` (lines 194, 224-247 for the Stop branch, and the `orderVal` read at line 359, `itineraryOrder: orderVal` at line 368 and 383).
- The `TextFormField` for "Ordine nell'itinerario" in `build()` (lines 525-563).

- [ ] **Step 2: Replace the date portion of `_stopDateTime` with a day dropdown + keep a time picker**

Replace the state declaration at line 39:

```dart
  DateTime _stopDateTime = DateTime.now();
```

with:

```dart
  int _selectedDayIndex = 0;
  TimeOfDay _stopTime = TimeOfDay.now();
```

In `initState`, replace the block at lines 87-100:

```dart
    if (!isActivity) {
      if (isEdit) {
        _stopDateTime = widget.stop!.dateTime;
      } else {
        if (_trip != null) {
          final now = DateTime.now();
          if (now.isAfter(_trip!.startDate) && now.isBefore(_trip!.endDate)) {
            _stopDateTime = now;
          } else {
            _stopDateTime = _trip!.startDate;
          }
        }
      }
    }
```

with:

```dart
    if (!isActivity) {
      if (isEdit) {
        final stopDateTime = widget.stop!.dateTime;
        final tripStartDay = DateTime(_trip!.startDate.year, _trip!.startDate.month, _trip!.startDate.day);
        final stopDay = DateTime(stopDateTime.year, stopDateTime.month, stopDateTime.day);
        _selectedDayIndex = stopDay.difference(tripStartDay).inDays;
        _stopTime = TimeOfDay.fromDateTime(stopDateTime);
      } else if (_trip != null) {
        final now = DateTime.now();
        final tripStartDay = DateTime(_trip!.startDate.year, _trip!.startDate.month, _trip!.startDate.day);
        final tripEndDay = DateTime(_trip!.endDate.year, _trip!.endDate.month, _trip!.endDate.day);
        final today = DateTime(now.year, now.month, now.day);
        if (!today.isBefore(tripStartDay) && !today.isAfter(tripEndDay)) {
          _selectedDayIndex = today.difference(tripStartDay).inDays;
          _stopTime = TimeOfDay.fromDateTime(now);
        } else {
          _selectedDayIndex = 0;
          _stopTime = TimeOfDay.now();
        }
      }
    }
```

Replace `_selectDateTime()` (lines 142-175), which currently opens both a date and time picker, with a time-only picker:

```dart
  Future<void> _selectStopTime() async {
    final timePicked = await showTimePicker(
      context: context,
      initialTime: _stopTime,
    );
    if (timePicked != null) {
      setState(() {
        _stopTime = timePicked;
      });
    }
  }
```

Add a getter that combines the dropdown day + picked time into the `DateTime` needed for `Stop.dateTime`, placed right after `_selectStopTime`:

```dart
  DateTime get _combinedStopDateTime {
    final dayDate = _trip!.startDate.add(Duration(days: _selectedDayIndex));
    return DateTime(dayDate.year, dayDate.month, dayDate.day, _stopTime.hour, _stopTime.minute);
  }
```

- [ ] **Step 3: Update `_save()` to use `_combinedStopDateTime` and drop `itineraryOrder` input**

In the Stop branch of `_save()` (originally lines 358-391), replace both `Stop(...)` / `copyWith(...)` calls' `dateTime:` and `itineraryOrder:` arguments:

```dart
      if (widget.stop == null) {
        // Adding a Stop
        final newStop = Stop(
          tripId: widget.tripId,
          name: name.trim(),
          description: description.trim(),
          dateTime: _combinedStopDateTime,
          location: location.trim(),
          itineraryOrder: 1, // overwritten by TravelProvider.addStop based on date
          notes: notesText.trim(),
        );
        provider.addStop(newStop);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tappa '${name.trim()}' aggiunta con successo!")),
        );
      } else {
        // Editing a Stop
        final updatedStop = widget.stop!.copyWith(
          name: name.trim(),
          description: description.trim(),
          dateTime: _combinedStopDateTime,
          location: location.trim(),
          notes: notesText.trim(),
        );
        provider.updateStop(updatedStop);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tappa '${name.trim()}' modificata con successo!")),
        );
      }
```

Note `updatedStop` no longer passes `itineraryOrder:` — `copyWith` keeps `widget.stop!.itineraryOrder`, and `TravelProvider.updateStop` overwrites it anyway.

Also remove the now-orphaned `orderText`/order-validation code still present earlier in `_save()` (the `final orderText = ...` line and the whole "Ordine nell'itinerario" validation `if` block from Step 1 — verify both removals landed; the `_save` method must compile with no reference to `_itineraryOrderController` or `orderText` left).

- [ ] **Step 4: Replace the date-picker `InkWell` with a day dropdown + time-picker row in `build()`**

Replace the "Order in itinerary input" `TextFormField` block (already removed in Step 1) and the "Stop DateTime Picker Card" `InkWell` block (originally lines 566-600) with:

```dart
                // Day dropdown (bounded to the trip's actual days)
                Builder(builder: (context) {
                  final tripStartDay = DateTime(_trip!.startDate.year, _trip!.startDate.month, _trip!.startDate.day);
                  final tripEndDay = DateTime(_trip!.endDate.year, _trip!.endDate.month, _trip!.endDate.day);
                  final totalDays = tripEndDay.difference(tripStartDay).inDays + 1;
                  return DropdownButtonFormField<int>(
                    value: _selectedDayIndex,
                    decoration: InputDecoration(
                      labelText: "Giorno del viaggio *",
                      prefixIcon: const Icon(Icons.calendar_month),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: List.generate(totalDays, (i) {
                      final dayDate = tripStartDay.add(Duration(days: i));
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Text("Giorno ${i + 1} - ${_formatDate(dayDate)}"),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDayIndex = val;
                        });
                      }
                    },
                  );
                }),
                const SizedBox(height: 20),

                // Stop time picker
                InkWell(
                  onTap: _selectStopTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ora *",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "${_stopTime.hour.toString().padLeft(2, '0')}:${_stopTime.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
```

- [ ] **Step 5: Static-check the file**

Run: `flutter analyze lib/screens/add_stop_screen.dart`
Expected: No new errors (pre-existing `withOpacity`/`use_build_context_synchronously` infos are fine and untouched; there must be zero references left to `_itineraryOrderController`, `orderText`, `_selectDateTime`, or `_stopDateTime` — all renamed/replaced in prior steps).

- [ ] **Step 6: Manual verification**

Run: `flutter run` (any available device/emulator), then:
1. Open a trip, go to "Itinerario", tap the "+" FAB to add a stop.
2. Confirm the form shows a "Giorno del viaggio" dropdown listing every day of the trip (no more free date picker, no more "Ordine nell'itinerario" field) and an "Ora" picker.
3. Add two stops on the same selected day with different times.
4. Confirm both appear in the itinerary tab labeled with the same "Giorno N", ordered by time.
5. Edit one of the two stops, change its day via the dropdown to a different day, save, and confirm it now appears under the new day's label.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/add_stop_screen.dart
git commit -m "$(cat <<'EOF'
Replace manual itinerary order field with a trip-day dropdown

AddStopScreen now lets users pick from the trip's actual days instead
of typing a free order number or picking an out-of-range date, making
it clear multiple stops can share the same day.
EOF
)"
```

---

## Self-review notes

- **Spec coverage:** Task 1 covers the spec's "provider" section (derive itineraryOrder, delete `_reorderStops`); Task 2 covers the spec's "AddStopScreen" section (dropdown, remove manual order field, remove free date picker). The spec's "database_helper.dart: no change" and "trip_details_screen.dart: no change" items require no task — confirmed no task touches either file.
- **Placeholder scan:** none found; every step has literal code.
- **Type consistency:** `Stop.copyWith` (used in Task 1 and Task 2) already supports `itineraryOrder` as a named optional parameter per the existing model (`lib/models/stop.dart:56-80`) — no signature changes needed there. `TravelProvider.addStop`/`updateStop` signatures (`Future<void> addStop(Stop stop)`, `Future<void> updateStop(Stop stop)`) are unchanged, so no caller elsewhere in the codebase needs updating (checked: only `add_stop_screen.dart` calls them).
