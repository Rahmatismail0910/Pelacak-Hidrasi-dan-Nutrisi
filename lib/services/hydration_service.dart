import 'database_service.dart';

class HydrationService {
  HydrationService._();

  static final HydrationService instance = HydrationService._();

  String _todayKey() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> saveHydration({
    required int userId,
    required int amountMl,
    required int targetMl,
  }) async {
    if (amountMl <= 0) {
      throw ArgumentError('Jumlah air harus lebih dari 0 ml.');
    }

    final db = await DatabaseService.instance.database;
    final now = DateTime.now();
    final dateKey = _todayKey();

    await db.transaction((txn) async {
      await txn.insert('hydration_logs', {
        'user_id': userId,
        'schedule_id': null,
        'consumed_ml': amountMl,
        'consumed_at': now.toIso8601String(),
        'date_key': dateKey,
      });

      await txn.rawInsert(
        '''
        INSERT INTO daily_summaries (
          user_id,
          date_key,
          target_water_ml,
          total_water_ml,
          updated_at
        )
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(user_id, date_key)
        DO UPDATE SET
          target_water_ml = excluded.target_water_ml,
          total_water_ml = daily_summaries.total_water_ml
                            + excluded.total_water_ml,
          updated_at = excluded.updated_at
        ''',
        [userId, dateKey, targetMl, amountMl, now.toIso8601String()],
      );
    });
  }

  Future<Map<String, Object?>> getTodaySummary(int userId) async {
    final db = await DatabaseService.instance.database;

    final results = await db.query(
      'daily_summaries',
      where: 'user_id = ? AND date_key = ?',
      whereArgs: [userId, _todayKey()],
      limit: 1,
    );

    if (results.isEmpty) {
      return {'target_water_ml': 0, 'total_water_ml': 0};
    }

    return results.first;
  }
}
