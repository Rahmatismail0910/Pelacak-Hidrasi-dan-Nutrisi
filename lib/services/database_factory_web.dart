import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

DatabaseFactory getAppDatabaseFactory() {
  return databaseFactoryFfiWeb;
}

Future<String> getDatabasePath() async {
  return 'hydration_nutrition_tracker.db';
}
