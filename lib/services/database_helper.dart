import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';
import '../models/stop.dart';
import '../models/activity.dart';
import '../models/checklist_item.dart';
import '../models/expense.dart';
import '../models/useful_info.dart';
import '../models/diary_entry.dart';
import '../models/travel_document.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  @visibleForTesting
  Future<void> resetDatabaseForTest() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
    _database = null;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('travel_planner.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version:
          10, // Database aggiornato alla versione 10 per supportare l'associazione dei ricordi a tappe/attività
      onCreate: _createDB,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onConfigure(Database db) async {
    // Abilita il vincolo delle chiavi esterne per supportare l'eliminazione a cascata
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const integerType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const doubleNullableType = 'REAL';

    // Tabella dei Viaggi (aggiornata alla versione 2)
    await db.execute('''
      CREATE TABLE trips (
        id $idType,
        title $textType,
        destination $textType,
        startDate $textType,
        endDate $textType,
        coverImagePath $textNullableType,
        budget $doubleType,
        status TEXT NOT NULL DEFAULT 'futuro',
        participants TEXT NOT NULL DEFAULT '',
        generalInfo TEXT NOT NULL DEFAULT '',
        latitude REAL,
        longitude REAL
      )
    ''');

    // Tabella delle Tappe (Fermate dell'itinerario)
    await db.execute('''
      CREATE TABLE stops (
        id $idType,
        tripId $integerType,
        name $textType,
        description $textType,
        dateTime $textType,
        location $textType,
        itineraryOrder $integerType,
        notes $textNullableType,
        latitude $doubleNullableType,
        longitude $doubleNullableType,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Tabella delle Attività
    await db.execute('''
      CREATE TABLE activities (
        id $idType,
        stopId $integerType,
        name $textType,
        type $textType,
        description $textType,
        time $textType,
        cost $doubleType,
        location $textType,
        status TEXT NOT NULL DEFAULT 'Da svolgere',
        notes TEXT,
        FOREIGN KEY (stopId) REFERENCES stops (id) ON DELETE CASCADE
      )
    ''');

    // Tabella degli elementi della Checklist e bagagli
    await db.execute('''
      CREATE TABLE checklist_items (
        id $idType,
        tripId $integerType,
        itemText $textType,
        isChecked $integerType,
        category $textType DEFAULT 'Bagaglio',
        priority $textType DEFAULT 'Media',
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Tabella delle Spese
    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        tripId $integerType,
        title $textType,
        amount $doubleType,
        category $textType,
        date $textType,
        associatedType $textType,
        associatedId INTEGER,
        associatedName $textType,
        paymentMethod $textType,
        status $textType,
        notes $textType,
        currency $textType,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Tabella delle Informazioni Utili
    await db.execute('''
      CREATE TABLE useful_info (
        id $idType,
        tripId $integerType,
        title $textType,
        content $textType,
        category $textType,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Tabella delle voci del Diario di Bordo (Ricordi)
    await db.execute('''
      CREATE TABLE diary_entries (
        id $idType,
        tripId $integerType,
        title $textType,
        content $textType,
        date $textType,
        imagePath $textNullableType,
        associatedType TEXT NOT NULL DEFAULT 'Generale',
        associatedId INTEGER,
        associatedName TEXT NOT NULL DEFAULT 'Generale',
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Tabella dei Documenti di Viaggio (Biglietti)
    await db.execute('''
      CREATE TABLE travel_documents (
        id $idType,
        tripId $integerType,
        title $textType,
        documentType $textType,
        bookingCode $textNullableType,
        seat $textNullableType,
        gate $textNullableType,
        dateTime $textNullableType,
        notes $textNullableType,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Aggiunge le colonne per lo stato, i partecipanti, le info generali e le coordinate dei viaggi
      await db.execute(
        "ALTER TABLE trips ADD COLUMN status TEXT NOT NULL DEFAULT 'futuro'",
      );
      await db.execute(
        "ALTER TABLE trips ADD COLUMN participants TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE trips ADD COLUMN generalInfo TEXT NOT NULL DEFAULT ''",
      );
      await db.execute("ALTER TABLE trips ADD COLUMN latitude REAL");
      await db.execute("ALTER TABLE trips ADD COLUMN longitude REAL");
    }
    if (oldVersion < 3) {
      // Aggiunge l'ordine dell'itinerario e le note alla tabella delle tappe
      await db.execute(
        "ALTER TABLE stops ADD COLUMN itineraryOrder INTEGER NOT NULL DEFAULT 1",
      );
      await db.execute("ALTER TABLE stops ADD COLUMN notes TEXT DEFAULT ''");
    }
    if (oldVersion < 4) {
      // Aggiunge località, stato e note alla tabella delle attività
      await db.execute(
        "ALTER TABLE activities ADD COLUMN location TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE activities ADD COLUMN status TEXT NOT NULL DEFAULT 'Da svolgere'",
      );
      await db.execute(
        "ALTER TABLE activities ADD COLUMN notes TEXT DEFAULT ''",
      );
    }
    if (oldVersion < 5) {
      // Aggiunge la categoria alla checklist e crea la tabella delle info utili
      await db.execute(
        "ALTER TABLE checklist_items ADD COLUMN category TEXT NOT NULL DEFAULT 'Bagaglio'",
      );
      await db.execute('''
        CREATE TABLE useful_info (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tripId INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          category TEXT NOT NULL,
          FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      // Aggiorna la tabella delle spese: crea la nuova, copia i dati, elimina la vecchia e rinomina
      await db.execute('''
        CREATE TABLE expenses_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tripId INTEGER NOT NULL,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          date TEXT NOT NULL,
          associatedType TEXT NOT NULL DEFAULT 'Generale',
          associatedId INTEGER,
          associatedName TEXT NOT NULL DEFAULT 'Generale',
          paymentMethod TEXT NOT NULL DEFAULT 'Contanti',
          status TEXT NOT NULL DEFAULT 'Sostenuta',
          notes TEXT NOT NULL DEFAULT '',
          currency TEXT NOT NULL DEFAULT 'EUR',
          FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        INSERT INTO expenses_new (
          id, tripId, title, amount, category, date,
          associatedType, associatedId, associatedName,
          paymentMethod, status, notes, currency
        )
        SELECT 
          id, tripId, description, amount, category, date,
          'Generale', NULL, 'Generale',
          'Contanti', 'Sostenuta', '', currency
        FROM expenses
      ''');

      await db.execute('DROP TABLE expenses');
      await db.execute('ALTER TABLE expenses_new RENAME TO expenses');
    }
    if (oldVersion < 7) {
      await db.execute(
        "ALTER TABLE checklist_items ADD COLUMN priority TEXT NOT NULL DEFAULT 'Media'",
      );
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE diary_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tripId INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          date TEXT NOT NULL,
          imagePath TEXT,
          FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE travel_documents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tripId INTEGER NOT NULL,
          title TEXT NOT NULL,
          documentType TEXT NOT NULL,
          bookingCode TEXT,
          seat TEXT,
          gate TEXT,
          dateTime TEXT,
          notes TEXT,
          FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 10) {
      // Aggiunge le colonne di associazione alla tabella dei ricordi del diario
      await db.execute(
        "ALTER TABLE diary_entries ADD COLUMN associatedType TEXT NOT NULL DEFAULT 'Generale'",
      );
      await db.execute(
        "ALTER TABLE diary_entries ADD COLUMN associatedId INTEGER",
      );
      await db.execute(
        "ALTER TABLE diary_entries ADD COLUMN associatedName TEXT NOT NULL DEFAULT 'Generale'",
      );
    }
  }

 
  // OPERAZIONI CRUD SUI VIAGGI

  Future<Trip> insertTrip(Trip trip) async {
    final db = await instance.database;
    final id = await db.insert('trips', trip.toMap());
    return trip.copyWith(id: id);
  }

  Future<List<Trip>> getTrips() async {
    final db = await instance.database;
    final result = await db.query('trips', orderBy: 'startDate ASC');
    return result.map((json) => Trip.fromMap(json)).toList();
  }

  Future<Trip?> getTrip(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'trips',
      columns: [
        'id',
        'title',
        'destination',
        'startDate',
        'endDate',
        'coverImagePath',
        'budget',
        'status',
        'participants',
        'generalInfo',
        'latitude',
        'longitude',
      ],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await instance.database;
    return db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }


  // OPERAZIONI CRUD SULLE TAPPE

  Future<Stop> insertStop(Stop stop) async {
    final db = await instance.database;
    final id = await db.insert('stops', stop.toMap());
    return stop.copyWith(id: id);
  }

  Future<List<Stop>> getStopsForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'stops',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'itineraryOrder ASC, dateTime ASC',
    );
    return result.map((json) => Stop.fromMap(json)).toList();
  }

  Future<int> updateStop(Stop stop) async {
    final db = await instance.database;
    return db.update(
      'stops',
      stop.toMap(),
      where: 'id = ?',
      whereArgs: [stop.id],
    );
  }

  Future<int> deleteStop(int id) async {
    final db = await instance.database;
    return await db.delete('stops', where: 'id = ?', whereArgs: [id]);
  }


  // OPERAZIONI CRUD SULLE ATTIVITÀ

  Future<Activity> insertActivity(Activity activity) async {
    final db = await instance.database;
    final id = await db.insert('activities', activity.toMap());
    return activity.copyWith(id: id);
  }

  Future<List<Activity>> getActivitiesForStop(int stopId) async {
    final db = await instance.database;
    final result = await db.query(
      'activities',
      where: 'stopId = ?',
      whereArgs: [stopId],
      orderBy: 'time ASC',
    );
    return result.map((json) => Activity.fromMap(json)).toList();
  }

  Future<int> updateActivity(Activity activity) async {
    final db = await instance.database;
    return db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<int> deleteActivity(int id) async {
    final db = await instance.database;
    return await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }


  // OPERAZIONI CRUD SUGLI ELEMENTI DELLA CHECKLIST


  Future<ChecklistItem> insertChecklistItem(ChecklistItem item) async {
    final db = await instance.database;
    final id = await db.insert('checklist_items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<ChecklistItem>> getChecklistItemsForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'checklist_items',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'id ASC',
    );
    return result.map((json) => ChecklistItem.fromMap(json)).toList();
  }

  Future<int> updateChecklistItem(ChecklistItem item) async {
    final db = await instance.database;
    return db.update(
      'checklist_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteChecklistItem(int id) async {
    final db = await instance.database;
    return await db.delete('checklist_items', where: 'id = ?', whereArgs: [id]);
  }


  // OPERAZIONI CRUD SULLE SPESE


  Future<Expense> insertExpense(Expense expense) async {
    final db = await instance.database;
    final id = await db.insert('expenses', expense.toMap());
    return expense.copyWith(id: id);
  }

  Future<List<Expense>> getExpensesForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'date DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }


  // OPERAZIONI CRUD SULLE INFO UTILI


  Future<UsefulInfo> insertUsefulInfo(UsefulInfo info) async {
    final db = await instance.database;
    final id = await db.insert('useful_info', info.toMap());
    return info.copyWith(id: id);
  }

  Future<List<UsefulInfo>> getUsefulInfoForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'useful_info',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'id ASC',
    );
    return result.map((json) => UsefulInfo.fromMap(json)).toList();
  }

  Future<int> updateUsefulInfo(UsefulInfo info) async {
    final db = await instance.database;
    return db.update(
      'useful_info',
      info.toMap(),
      where: 'id = ?',
      whereArgs: [info.id],
    );
  }

  Future<int> deleteUsefulInfo(int id) async {
    final db = await instance.database;
    return await db.delete('useful_info', where: 'id = ?', whereArgs: [id]);
  }

  // Query globali su tutti i viaggi (usate per la dashboard di analisi e statistiche)
  Future<List<Stop>> getAllStops() async {
    final db = await instance.database;
    final result = await db.query('stops');
    return result.map((json) => Stop.fromMap(json)).toList();
  }

  Future<List<Activity>> getAllActivities() async {
    final db = await instance.database;
    final result = await db.query('activities');
    return result.map((json) => Activity.fromMap(json)).toList();
  }

  Future<List<ChecklistItem>> getAllChecklistItems() async {
    final db = await instance.database;
    final result = await db.query('checklist_items');
    return result.map((json) => ChecklistItem.fromMap(json)).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses');
    return result.map((json) => Expense.fromMap(json)).toList();
  }


  // OPERAZIONI CRUD SULLE VOCI DEL DIARIO DI BORDO


  Future<DiaryEntry> insertDiaryEntry(DiaryEntry entry) async {
    final db = await instance.database;
    final id = await db.insert('diary_entries', entry.toMap());
    return entry.copyWith(id: id);
  }

  Future<List<DiaryEntry>> getDiaryEntriesForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'diary_entries',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'date DESC',
    );
    return result.map((json) => DiaryEntry.fromMap(json)).toList();
  }

  Future<int> updateDiaryEntry(DiaryEntry entry) async {
    final db = await instance.database;
    return await db.update(
      'diary_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteDiaryEntry(int id) async {
    final db = await instance.database;
    return await db.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
  }


  // OPERAZIONI CRUD SUI DOCUMENTI DI VIAGGIO


  Future<TravelDocument> insertTravelDocument(TravelDocument doc) async {
    final db = await instance.database;
    final id = await db.insert('travel_documents', doc.toMap());
    return doc.copyWith(id: id);
  }

  Future<List<TravelDocument>> getTravelDocumentsForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'travel_documents',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'dateTime ASC',
    );
    return result.map((json) => TravelDocument.fromMap(json)).toList();
  }

  Future<int> updateTravelDocument(TravelDocument doc) async {
    final db = await instance.database;
    return await db.update(
      'travel_documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<int> deleteTravelDocument(int id) async {
    final db = await instance.database;
    return await db.delete(
      'travel_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Chiude la connessione al database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
