import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

DatabaseFactory getAppDatabaseFactory() {
  return databaseFactory;
}

Future<String> getDatabasePath() async {
  final directory = await getDatabasesPath();

  return p.join(directory, 'hydration_nutrition_tracker.db');
}
