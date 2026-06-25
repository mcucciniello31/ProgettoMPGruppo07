import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/stop.dart';
import '../models/activity.dart';
import '../models/checklist_item.dart';
import '../models/expense.dart';
import '../models/useful_info.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';

class TravelProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Trip> _trips = [];
  Trip? _selectedTrip;
  List<Stop> _currentStops = [];
  Map<int, List<Activity>> _stopActivities = {};
  List<ChecklistItem> _currentChecklist = [];
  List<Expense> _currentExpenses = [];
  List<UsefulInfo> _currentUsefulInfo = [];
  bool _isLoading = false;

  // Getters
  List<Trip> get trips => _trips;
  Trip? get selectedTrip => _selectedTrip;
  List<Stop> get currentStops => _currentStops;
  List<ChecklistItem> get currentChecklist => _currentChecklist;
  List<Expense> get currentExpenses => _currentExpenses;
  List<UsefulInfo> get currentUsefulInfo => _currentUsefulInfo;
  bool get isLoading => _isLoading;

  List<Activity> getActivitiesForStop(int stopId) {
    return _stopActivities[stopId] ?? [];
  }

  // Load all trips
  Future<void> loadTrips() async {
    _isLoading = true;
    notifyListeners();
    try {
      _trips = await _dbHelper.getTrips();
    } catch (e) {
      debugPrint('Error loading trips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set the selected trip and load all its details
  Future<void> selectTrip(Trip trip) async {
    _selectedTrip = trip;
    _isLoading = true;
    notifyListeners();

    try {
      await loadTripDetails(trip.id!);
    } catch (e) {
      debugPrint('Error selecting trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reload details for the selected trip
  Future<void> loadTripDetails(int tripId) async {
    _currentStops = await _dbHelper.getStopsForTrip(tripId);
    _currentChecklist = await _dbHelper.getChecklistItemsForTrip(tripId);
    _currentExpenses = await _dbHelper.getExpensesForTrip(tripId);
    _currentUsefulInfo = await _dbHelper.getUsefulInfoForTrip(tripId);

    // Load activities for all stops
    _stopActivities.clear();
    for (var stop in _currentStops) {
      final activities = await _dbHelper.getActivitiesForStop(stop.id!);
      _stopActivities[stop.id!] = activities;
    }
  }

  // ==========================================
  // TRIP OPERATIONS
  // ==========================================

  Future<void> addTrip(Trip trip) async {
    await _dbHelper.insertTrip(trip);
    await loadTrips();
  }

  Future<void> updateTrip(Trip trip) async {
    await _dbHelper.updateTrip(trip);
    if (_selectedTrip?.id == trip.id) {
      _selectedTrip = trip;
    }
    await loadTrips();
  }

  Future<void> deleteTrip(int id) async {
    await _dbHelper.deleteTrip(id);
    if (_selectedTrip?.id == id) {
      _selectedTrip = null;
    }
    await loadTrips();
  }

  // ==========================================
  // STOP OPERATIONS
  // ==========================================

  Future<void> _reorderStops(int tripId) async {
    final stops = await _dbHelper.getStopsForTrip(tripId);
    for (int i = 0; i < stops.length; i++) {
      final expectedOrder = i + 1;
      if (stops[i].itineraryOrder != expectedOrder) {
        await _dbHelper.updateStop(stops[i].copyWith(itineraryOrder: expectedOrder));
      }
    }
  }

  Future<void> addStop(Stop stop) async {
    final existingStops = await _dbHelper.getStopsForTrip(stop.tripId);
    // Shift existing stops that have order >= new order
    for (var existing in existingStops) {
      if (existing.itineraryOrder >= stop.itineraryOrder) {
        await _dbHelper.updateStop(existing.copyWith(
          itineraryOrder: existing.itineraryOrder + 1,
        ));
      }
    }
    await _dbHelper.insertStop(stop);
    await _reorderStops(stop.tripId);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> updateStop(Stop stop) async {
    final existingStops = await _dbHelper.getStopsForTrip(stop.tripId);
    final oldStop = existingStops.firstWhere((s) => s.id == stop.id);
    final oldOrder = oldStop.itineraryOrder;
    final newOrder = stop.itineraryOrder;

    if (oldOrder != newOrder) {
      for (var existing in existingStops) {
        if (existing.id == stop.id) continue;
        if (newOrder < oldOrder) {
          if (existing.itineraryOrder >= newOrder && existing.itineraryOrder < oldOrder) {
            await _dbHelper.updateStop(existing.copyWith(
              itineraryOrder: existing.itineraryOrder + 1,
            ));
          }
        } else {
          if (existing.itineraryOrder > oldOrder && existing.itineraryOrder <= newOrder) {
            await _dbHelper.updateStop(existing.copyWith(
              itineraryOrder: existing.itineraryOrder - 1,
            ));
          }
        }
      }
    }
    await _dbHelper.updateStop(stop);
    await _reorderStops(stop.tripId);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> deleteStop(int id) async {
    if (_selectedTrip != null) {
      await _dbHelper.deleteStop(id);
      await _reorderStops(_selectedTrip!.id!);
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  // ==========================================
  // ACTIVITY OPERATIONS
  // ==========================================

  Future<void> addActivity(Activity activity) async {
    await _dbHelper.insertActivity(activity);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> updateActivity(Activity activity) async {
    await _dbHelper.updateActivity(activity);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> deleteActivity(int id) async {
    await _dbHelper.deleteActivity(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  // ==========================================
  // CHECKLIST OPERATIONS
  // ==========================================

  Future<void> addChecklistItem(ChecklistItem item) async {
    await _dbHelper.insertChecklistItem(item);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> toggleChecklistItem(ChecklistItem item) async {
    final updatedItem = item.copyWith(isChecked: !item.isChecked);
    await _dbHelper.updateChecklistItem(updatedItem);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> deleteChecklistItem(int id) async {
    await _dbHelper.deleteChecklistItem(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> updateChecklistItem(ChecklistItem item) async {
    await _dbHelper.updateChecklistItem(item);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  // ==========================================
  // USEFUL INFO OPERATIONS
  // ==========================================

  Future<void> addUsefulInfo(UsefulInfo info) async {
    await _dbHelper.insertUsefulInfo(info);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> updateUsefulInfo(UsefulInfo info) async {
    await _dbHelper.updateUsefulInfo(info);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> deleteUsefulInfo(int id) async {
    await _dbHelper.deleteUsefulInfo(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  // ==========================================
  // EXPENSE OPERATIONS
  // ==========================================

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insertExpense(expense);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notifyListeners();
    }
  }

  // Helper getters for selected trip statistics
  double get totalBudget => _selectedTrip?.budget ?? 0.0;

  double get totalExpenses {
    return _currentExpenses
        .where((e) => e.status == 'Sostenuta')
        .fold(0.0, (sum, item) => sum + CurrencyService.convert(item.amount, item.currency, 'EUR'));
  }

  double get totalPlannedExpenses {
    return _currentExpenses
        .where((e) => e.status == 'Prevista')
        .fold(0.0, (sum, item) => sum + CurrencyService.convert(item.amount, item.currency, 'EUR'));
  }

  double get remainingBudget => totalBudget - totalExpenses;

  double get remainingBudgetPlanned => totalBudget - totalPlannedExpenses;

  double get checklistCompletionRate {
    if (_currentChecklist.isEmpty) return 0.0;
    final checkedCount = _currentChecklist.where((item) => item.isChecked).length;
    return checkedCount / _currentChecklist.length;
  }
}
