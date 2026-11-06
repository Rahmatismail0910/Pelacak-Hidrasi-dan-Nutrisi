import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = 'Mingguan';

  Future<List<Map<String, dynamic>>>? _dashboardFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_dashboardFuture == null) {
      _loadDashboard();
    }
  }

  void _loadDashboard() {
    final userId = context.read<AuthProvider>().currentUser?.id;

    if (userId == null) return;

    setState(() {
      _dashboardFuture = _selectedPeriod == 'Mingguan'
          ? DashboardService.instance.getWeeklyData(userId)
          : DashboardService.instance.getMonthlyData(userId);
    });
  }

  Future<void> _refreshDashboard() async {
    final userId = context.read<AuthProvider>().currentUser?.id;

    if (userId == null) return;

    final future = _selectedPeriod == 'Mingguan'
        ? DashboardService.instance.getWeeklyData(userId)
        : DashboardService.instance.getMonthlyData(userId);

    setState(() {
      _dashboardFuture = future;
    });

    await future;
  }

  void _changePeriod(String period) {
    if (_selectedPeriod == period) return;

    setState(() {
      _selectedPeriod = period;
      _dashboardFuture = null;
    });

    _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Silakan login terlebih dahulu.'))
          : RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text('Gagal memuat data dashboard.'),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: _refreshDashboard,
                            child: const Text('Coba lagi'),
                          ),
                        ),
                      ],
                    );
                  }

                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    return const Center(
                      child: Text('Belum ada data untuk ditampilkan.'),
                    );
                  }

                  final totalWater = data.fold<double>(
                    0,
                    (total, item) =>
                        total + (item['hydration'] as num).toDouble(),
                  );

                  final totalCalories = data.fold<double>(
                    0,
                    (total, item) =>
                        total + (item['calories'] as num).toDouble(),
                  );

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Ringkasan Konsumsi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pantau perkembangan hidrasi dan nutrisi kamu.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      // Pilihan periode grafik.
                      Center(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Mingguan',
                              label: Text('Mingguan'),
                              icon: Icon(Icons.calendar_view_week),
                            ),
                            ButtonSegment(
                              value: 'Bulanan',
                              label: Text('Bulanan'),
                              icon: Icon(Icons.calendar_month),
                            ),
                          ],
                          selected: {_selectedPeriod},
                          onSelectionChanged: (selection) {
                            _changePeriod(selection.first);
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Ringkasan hidrasi.
                      _buildSummaryCard(
                        title: 'Total Hidrasi',
                        value: '${totalWater.toStringAsFixed(0)} ml',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 12),

                      // Ringkasan nutrisi.
                      _buildSummaryCard(
                        title: 'Total Kalori',
                        value: '${totalCalories.toStringAsFixed(0)} kkal',
                        icon: Icons.restaurant,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Grafik Hidrasi dan Nutrisi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildLegend(),

                      const SizedBox(height: 16),

                      _buildChart(data),

                      const SizedBox(height: 16),

                      Text(
                        '* Grafik menampilkan jumlah konsumsi air (ml) '
                        'dan kalori (kkal) berdasarkan tanggal.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 20,
      children: [
        _legendItem(Colors.blue, 'Hidrasi (ml)'),
        _legendItem(Colors.green, 'Nutrisi (kkal)'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    final waterSpots = <FlSpot>[];
    final calorieSpots = <FlSpot>[];

    for (var i = 0; i < data.length; i++) {
      waterSpots.add(
        FlSpot(i.toDouble(), (data[i]['hydration'] as num).toDouble()),
      );

      calorieSpots.add(
        FlSpot(i.toDouble(), (data[i]['calories'] as num).toDouble()),
      );
    }

    final values = [
      ...waterSpots.map((spot) => spot.y),
      ...calorieSpots.map((spot) => spot.y),
    ];

    final highestValue = values.isEmpty
        ? 1000.0
        : values.reduce((a, b) => a > b ? a : b);

    final maxY = highestValue == 0 ? 1000.0 : highestValue * 1.2;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: SizedBox(
          height: 280,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: true,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final label = spot.barIndex == 0 ? 'Hidrasi' : 'Nutrisi';

                      final unit = spot.barIndex == 0 ? 'ml' : 'kkal';

                      return LineTooltipItem(
                        '$label\n${spot.y.toStringAsFixed(0)} $unit',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Jumlah (ml / kkal)',
                    style: TextStyle(fontSize: 10),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Tanggal',
                    style: TextStyle(fontSize: 11),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: data.length > 1 ? (data.length - 1) / 3 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();

                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }

                      final date = DateTime.tryParse(
                        data[index]['date'].toString(),
                      );

                      if (date == null) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: waterSpots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withValues(alpha: 0.08),
                  ),
                ),
                LineChartBarData(
                  spots: calorieSpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
