import 'database_service.dart';

class DashboardService {
  DashboardService._();

  static final DashboardService instance = DashboardService._();

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<List<Map<String, dynamic>>> _getChartData({
    required int userId,
    required int days,
  }) async {
    final db = await DatabaseService.instance.database;

    final today = DateTime.now();

    final dates = List.generate(
      days,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: days - 1 - index)),
    );

    final startDate = _dateKey(dates.first);
    final endDate = _dateKey(dates.last);

    final hydrationResults = await db.rawQuery(
      '''
      SELECT date_key, SUM(consumed_ml) AS total
      FROM hydration_logs
      WHERE user_id = ?
        AND date_key BETWEEN ? AND ?
      GROUP BY date_key
      ORDER BY date_key
      ''',
      [userId, startDate, endDate],
    );

    final nutritionResults = await db.rawQuery(
      '''
      SELECT date_key, SUM(calories) AS total
      FROM nutrition_logs
      WHERE user_id = ?
        AND date_key BETWEEN ? AND ?
      GROUP BY date_key
      ORDER BY date_key
      ''',
      [userId, startDate, endDate],
    );

    final hydrationMap = <String, double>{
      for (final row in hydrationResults)
        row['date_key'] as String: (row['total'] as num?)?.toDouble() ?? 0.0,
    };

    final nutritionMap = <String, double>{
      for (final row in nutritionResults)
        row['date_key'] as String: (row['total'] as num?)?.toDouble() ?? 0.0,
    };

    return dates.map((date) {
      final key = _dateKey(date);

      return <String, dynamic>{
        'date': key,
        'hydration': hydrationMap[key] ?? 0.0,
        'calories': nutritionMap[key] ?? 0.0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getWeeklyData(int userId) {
    return _getChartData(userId: userId, days: 7);
  }

  Future<List<Map<String, dynamic>>> getMonthlyData(int userId) {
    return _getChartData(userId: userId, days: 30);
  }
}
