# Itinerary day selection — design

## Problem

A trip has a fixed date range (`Trip.startDate`/`Trip.endDate`). Within that range, users should be able to add multiple stops (tappe) per day, and multiple activities per stop — both already supported by the data model (`Stop.dateTime`, `Activity.stopId`).

The actual bug is in the UI: `Stop.itineraryOrder` is a number typed manually by the user in `AddStopScreen` ("Ordine nell'itinerario"), separate from the stop's actual `dateTime` (chosen via a free date/time picker bounded to the trip range). `TripDetailsScreen` then labels each stop `"Giorno ${stop.itineraryOrder}"`, treating this manual order as if it were the day number. When two stops fall on the same calendar day, they get sequential `itineraryOrder` values (e.g. 1, 2) and are mislabeled as "Giorno 1" and "Giorno 2" instead of both being "Giorno 1".

## Solution

Turn `itineraryOrder` into a value derived from the stop's real date (day offset from `trip.startDate`, 1-indexed) instead of a free-typed number. Replace the manual order field and free date picker in `AddStopScreen` with a closed dropdown listing only the trip's actual days, plus the existing time picker for ordering within a day.

## Changes

### 1. `lib/screens/add_stop_screen.dart`

- Remove `_itineraryOrderController` and its validation block (both in `_save` and the `TextFormField` validator) entirely — no more "non puoi saltare giorni" logic.
- Remove the free `showDatePicker` call in `_selectDateTime` (keep the time picker part).
- Add `int _selectedDayIndex` (0-indexed) state, initialized from:
  - Edit mode: `widget.stop!.dateTime.difference(tripStartDay).inDays`.
  - Add mode: 0 (or the day matching `DateTime.now()` if it falls within trip range, mirroring current behavior).
- Add a `DropdownButtonFormField<int>` with one entry per day in `[trip.startDate, trip.endDate]` inclusive, labeled `"Giorno ${i+1} - dd/mm/yyyy"`.
- Keep the existing time picker UI/button to pick hour/minute; combine `selected day + picked time` into the `Stop.dateTime` passed to `provider.addStop`/`updateStop`.
- `itineraryOrder` is no longer read from a text field; pass a placeholder value (e.g. `1`) into the `Stop` constructor — the provider will overwrite it based on date (see below), so the value passed here is irrelevant but the field stays required by the model.

### 2. `lib/providers/travel_provider.dart`

- In `addStop(Stop stop)` and `updateStop(Stop stop)`: before persisting, recompute `itineraryOrder` as `stop.dateTime.difference(tripStartDay).inDays + 1` (using the selected trip's `startDate`, day-truncated), via `stop.copyWith(itineraryOrder: computedOrder)`.
- Delete `_reorderStops` and its call sites in `addStop`/`updateStop`/`deleteStop` — no longer needed since `itineraryOrder` is derived, not a manually-maintained dense sequence.

### 3. `lib/services/database_helper.dart`

- No change needed: `ORDER BY itineraryOrder ASC, dateTime ASC` already produces the right grouping once `itineraryOrder` reflects the real day.

## Out of scope

- No DB schema/migration change (column stays, only its producer changes).
- No changes to `Activity` (multiple activities per stop already works).
- No changes to `trip_details_screen.dart` display logic — `"Giorno ${stop.itineraryOrder}"` becomes correct automatically once the value is derived from date.

## Testing

- Manual: add two stops on the same day → both show "Giorno N" in the itinerary tab, ordered by time.
- Manual: add stops across different days → labels match the calendar view already present in `_buildItineraryCalendarView`.
- Manual: edit a stop, move it to a different day via the dropdown → label and ordering update correctly, no leftover gaps from the old manual-reorder logic.
