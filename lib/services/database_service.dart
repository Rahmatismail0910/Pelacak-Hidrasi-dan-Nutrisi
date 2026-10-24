//import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'database_factory_native.dart'
    if (dart.library.js_interop) 'database_factory_web.dart'
    as platform;

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final factory = platform.getAppDatabaseFactory();

    final options = OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );

    return factory.openDatabase(
      await platform.getDatabasePath(),
      options: options,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        age INTEGER,
        height_cm REAL,
        weight_kg REAL,
        gender TEXT,
        activity_level TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE hydration_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        time TEXT NOT NULL,
        target_ml INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE hydration_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        schedule_id INTEGER,
        consumed_ml INTEGER NOT NULL,
        consumed_at TEXT NOT NULL,
        date_key TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (schedule_id)
          REFERENCES hydration_schedules(id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        portion_grams REAL NOT NULL DEFAULT 0,
        calories REAL NOT NULL DEFAULT 0,
        is_consumed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (schedule_id)
          REFERENCES meal_schedules(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrition_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        meal_item_id INTEGER,
        food_name TEXT NOT NULL,
        portion_grams REAL NOT NULL DEFAULT 0,
        calories REAL NOT NULL DEFAULT 0,
        consumed_at TEXT NOT NULL,
        date_key TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (meal_item_id)
          REFERENCES meal_items(id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_summaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date_key TEXT NOT NULL,
        target_water_ml INTEGER NOT NULL DEFAULT 0,
        total_water_ml INTEGER NOT NULL DEFAULT 0,
        target_calories REAL NOT NULL DEFAULT 0,
        total_calories REAL NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        UNIQUE (user_id, date_key),
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_hydration_logs_user_date '
      'ON hydration_logs(user_id, date_key)',
    );

    await db.execute(
      'CREATE INDEX idx_nutrition_logs_user_date '
      'ON nutrition_logs(user_id, date_key)',
    );

    await db.execute(
      'CREATE INDEX idx_meal_schedules_user '
      'ON meal_schedules(user_id)',
    );
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Tambahkan migrasi secara bertahap jika struktur database berubah.
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;

    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;

    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;

    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) return;

    await db.close();
    _database = null;
  }

  Future<void> disposeForTesting() => close();
}
