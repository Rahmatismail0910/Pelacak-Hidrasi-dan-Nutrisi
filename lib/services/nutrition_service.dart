
import 'database_service.dart';

class NutritionService {
  NutritionService._();

  static final NutritionService instance = NutritionService._();

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> saveFood({
    required int userId,
    required String foodName,
    required double portionGrams,
    required double calories,
    required String mealType,
  }) async {
    if (foodName.trim().isEmpty ||
        portionGrams <= 0 ||
        calories < 0) {
      throw ArgumentError('Data makanan tidak valid.');
    }

    final db = await DatabaseService.instance.database;
    final now = DateTime.now();
    final dateKey = _todayKey();

    await db.transaction((txn) async {
      final schedules = await txn.query(
        'meal_schedules',
        where: 'user_id = ? AND meal_type = ? AND is_active = 1',
        whereArgs: [userId, mealType],
        limit: 1,
      );

      int scheduleId;

      if (schedules.isNotEmpty) {
        scheduleId = schedules.first['id'] as int;
      } else {
        scheduleId = await txn.insert('meal_schedules', {
          'user_id': userId,
          'title': mealType,
          'start_time': '00:00',
          'end_time': '23:59',
          'meal_type': mealType,
          'is_active': 1,
          'created_at': now.toIso8601String(),
        });
      }

      final mealItemId = await txn.insert('meal_items', {
        'schedule_id': scheduleId,
        'name': foodName.trim(),
        'portion_grams': portionGrams,
        'calories': calories,
        'is_consumed': 1,
      });

      await txn.insert('nutrition_logs', {
        'user_id': userId,
        'meal_item_id': mealItemId,
        'food_name': foodName.trim(),
        'portion_grams': portionGrams,
        'calories': calories,
        'consumed_at': now.toIso8601String(),
        'date_key': dateKey,
      });

      await txn.rawInsert(
        '''
        INSERT INTO daily_summaries (
          user_id, date_key, target_calories,
          total_calories, updated_at
        )
        VALUES (?, ?, 0, ?, ?)
        ON CONFLICT(user_id, date_key)
        DO UPDATE SET
          total_calories =
            daily_summaries.total_calories + excluded.total_calories,
          updated_at = excluded.updated_at
        ''',
        [userId, dateKey, calories, now.toIso8601String()],
      );
    });
  }

  Future<List<Map<String, Object?>>> getTodayFoods(int userId) async {
    final db = await DatabaseService.instance.database;

    return db.rawQuery(
      '''
      SELECT nutrition_logs.*, meal_schedules.meal_type
      FROM nutrition_logs
      LEFT JOIN meal_items
        ON nutrition_logs.meal_item_id = meal_items.id
      LEFT JOIN meal_schedules
        ON meal_items.schedule_id = meal_schedules.id
      WHERE nutrition_logs.user_id = ?
        AND nutrition_logs.date_key = ?
      ORDER BY nutrition_logs.consumed_at DESC
      ''',
      [userId, _todayKey()],
    );
  }

  Future<double> getTodayCalories(int userId) async {
    final db = await DatabaseService.instance.database;

    final result = await db.query(
      'daily_summaries',
      columns: ['total_calories'],
      where: 'user_id = ? AND date_key = ?',
      whereArgs: [userId, _todayKey()],
      limit: 1,
    );

    if (result.isEmpty) return 0;

    return (result.first['total_calories'] as num?)?.toDouble() ?? 0;
  }
}
