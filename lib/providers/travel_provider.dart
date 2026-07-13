import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/trip.dart';
import '../models/stop.dart';
import '../models/activity.dart';
import '../models/checklist_item.dart';
import '../models/expense.dart';
import '../models/useful_info.dart';
import '../models/diary_entry.dart';
import '../models/travel_document.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
part 'itinerary_provider.dart';
part 'checklist_provider.dart';
part 'expenses_provider.dart';
part 'diary_provider.dart';
part 'useful_info_provider.dart';

class TravelProvider with ChangeNotifier {
  static String? documentsDirectoryPath;

  static String? resolveImagePath(String? originalPath) {
    if (originalPath == null || originalPath.isEmpty) return null;

    // Se non è un percorso assoluto locale, lo restituisce così com'è
    if (!originalPath.startsWith('/') && !originalPath.contains(':/')) {
      return originalPath;
    }

    // Se il file esiste direttamente nel percorso originale, lo usa
    if (File(originalPath).existsSync()) {
      return originalPath;
    }

    // Altrimenti, cerca il file all'interno della directory documenti attuale
    final docsDir = documentsDirectoryPath;
    if (docsDir != null) {
      try {
        final fileName = path.basename(originalPath);
        final resolvedPath = "$docsDir/$fileName";
        if (File(resolvedPath).existsSync()) {
          return resolvedPath;
        }
      } catch (e) {
        debugPrint("Error resolving path: $e");
      }
    }

    return null; // Non trovato
  }

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Trip> _trips = [];
  Trip? _selectedTrip;
  List<Stop> _currentStops = [];
  final Map<int, List<Activity>> _stopActivities = {};
  List<ChecklistItem> _currentChecklist = [];
  List<Expense> _currentExpenses = [];
  List<UsefulInfo> _currentUsefulInfo = [];
  List<DiaryEntry> _currentDiaryEntries = [];
  List<TravelDocument> _currentTravelDocuments = [];
  bool _isLoading = false;

  // Getter
  List<Trip> get trips => _trips;
  Trip? get selectedTrip => _selectedTrip;
  List<Stop> get currentStops => _currentStops;
  List<ChecklistItem> get currentChecklist => _currentChecklist;
  List<Expense> get currentExpenses => _currentExpenses;
  List<UsefulInfo> get currentUsefulInfo => _currentUsefulInfo;
  List<DiaryEntry> get currentDiaryEntries => _currentDiaryEntries;
  List<TravelDocument> get currentTravelDocuments => _currentTravelDocuments;
  bool get isLoading => _isLoading;

  List<Activity> getActivitiesForStop(int stopId) {
    return _stopActivities[stopId] ?? [];
  }

  // Carica tutti i viaggi
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

  // Imposta il viaggio selezionato e carica tutti i suoi dettagli
  Future<void> selectTrip(Trip trip) async {
    _selectedTrip = trip;
    try {
      await loadTripDetails(trip.id!);
    } catch (e) {
      debugPrint('Error selecting trip: $e');
    }
    notifyListeners();
  }

  // Ricarica i dettagli del viaggio selezionato
  Future<void> loadTripDetails(int tripId) async {
    _currentStops = await _dbHelper.getStopsForTrip(tripId);
    _currentChecklist = await _dbHelper.getChecklistItemsForTrip(tripId);
    _currentExpenses = await _dbHelper.getExpensesForTrip(tripId);
    _currentUsefulInfo = await _dbHelper.getUsefulInfoForTrip(tripId);
    _currentDiaryEntries = await _dbHelper.getDiaryEntriesForTrip(tripId);
    _currentTravelDocuments = await _dbHelper.getTravelDocumentsForTrip(tripId);

    // Carica le attività per tutte le tappe
    _stopActivities.clear();
    for (var stop in _currentStops) {
      final activities = await _dbHelper.getActivitiesForStop(stop.id!);
      _stopActivities[stop.id!] = activities;
    }
  }


  // OPERAZIONI SUI VIAGGI

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

  double get checklistCompletionRate {
    if (_currentChecklist.isEmpty) return 0.0;
    final checkedCount = _currentChecklist
        .where((item) => item.isChecked)
        .length;
    return checkedCount / _currentChecklist.length;
  }

  void notify() => notifyListeners();
}
