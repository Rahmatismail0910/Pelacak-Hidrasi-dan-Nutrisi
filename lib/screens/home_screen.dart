import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/hydration_service.dart';
import '../services/nutrition_service.dart';

import 'login_screen.dart';
import 'hydration_screen.dart';
import 'nutrition_screen.dart';
import 'dashboard_screen.dart';
<<<<<<< Updated upstream
=======
import 'profile_screen.dart';
>>>>>>> Stashed changes
import 'notification_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, Object?>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  // Mengambil ringkasan hidrasi dan nutrisi dari database.
  Future<Map<String, Object?>> _loadSummary() async {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      return {'total_water_ml': 0, 'target_water_ml': 0, 'total_calories': 0};
    }

    final hydration = await HydrationService.instance.getTodaySummary(user.id);

    final calories = await NutritionService.instance.getTodayCalories(user.id);

    return {
      'total_water_ml': hydration['total_water_ml'] ?? 0,
      'target_water_ml': hydration['target_water_ml'] ?? 0,
      'total_calories': calories,
    };
  }

  // Memuat ulang ringkasan.
  Future<void> _refreshSummary() async {
    final future = _loadSummary();

    setState(() {
      _summaryFuture = future;
    });

    await future;
  }

  // Navigasi ke halaman Hidrasi.
  Future<void> _openHydration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HydrationScreen()),
    );

    if (!mounted) return;

    await _refreshSummary();
  }

  // Navigasi ke halaman Nutrisi.
  Future<void> _openNutrition() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NutritionScreen()),
    );

    if (!mounted) return;

    await _refreshSummary();
  }

  // Navigasi ke halaman Dashboard.
  Future<void> _openDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );

    if (!mounted) return;

    await _refreshSummary();
  }

  // Navigasi ke halaman Notifikasi.
  Future<void> _openNotification() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  // Navigasi ke halaman Profil.
  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  // Fungsi logout.
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final user = context.watch<AuthProvider>().currentUser;
    final userName = user?.name ?? 'Pengguna';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Beranda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salam pengguna.
                Text(
                  'Halo, $userName!',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                // Tanggal dan waktu otomatis.
                StreamBuilder<DateTime>(
                  stream: Stream.periodic(
                    const Duration(seconds: 1),
                    (_) => DateTime.now(),
                  ),
                  initialData: now,
                  builder: (context, snapshot) {
                    final currentTime = snapshot.data ?? DateTime.now();

                    final date = MaterialLocalizations.of(context)
                        .formatFullDate(currentTime);

                    final time =
                        '${currentTime.hour.toString().padLeft(2, '0')}:'
                        '${currentTime.minute.toString().padLeft(2, '0')}:'
                        '${currentTime.second.toString().padLeft(2, '0')}';

                    return Text(
                      '$date • $time',
                      style: TextStyle(color: Colors.grey.shade600),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Kartu pengenalan.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite, size: 36, color: Colors.blue),
                      SizedBox(height: 12),
                      Text(
                        'Mulai Hari Lebih Sehat',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pantau konsumsi air minum dan asupan '
                        'kalori untuk membantu menjaga pola '
                        'hidup sehat.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Ringkasan Hari Ini',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 14),

                // Ringkasan data dari database.
                FutureBuilder<Map<String, Object?>>(
                  future: _summaryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('Gagal memuat ringkasan.'),
                              TextButton(
                                onPressed: _refreshSummary,
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final summary = snapshot.data ?? {};

                    final totalWater =
                        (summary['total_water_ml'] as num?)?.toInt() ?? 0;

                    final totalCalories =
                        (summary['total_calories'] as num?)?.toDouble() ?? 0;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.water_drop,
                            title: 'Hidrasi',
                            value: '$totalWater ml',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.local_fire_department,
                            title: 'Kalori',
                            value: '${totalCalories.toStringAsFixed(0)} kkal',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  'Menu Utama',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 14),

                // 1. Menu Hidrasi.
                _buildMenuCard(
                  icon: Icons.water_drop,
                  title: 'Hidrasi',
                  subtitle: 'Hitung kebutuhan air dan atur jadwal minum.',
                  color: Colors.blue,
                  onTap: _openHydration,
                ),

                // 2. Menu Nutrisi.
                _buildMenuCard(
                  icon: Icons.restaurant,
                  title: 'Nutrisi',
                  subtitle: 'Catat makanan dan hitung kalori harian.',
                  color: Colors.green,
                  onTap: _openNutrition,
                ),

                // 3. Menu Dashboard.
                _buildMenuCard(
                  icon: Icons.bar_chart,
                  title: 'Dashboard',
                  subtitle: 'Pantau grafik perkembangan hidrasi dan nutrisi.',
                  color: Colors.purple,
                  onTap: _openDashboard,
                ),

                // 4. Menu Notifikasi.
                _buildMenuCard(
                  icon: Icons.notifications,
                  title: 'Notifikasi',
                  subtitle: 'Lihat pengingat jadwal minum dan aktivitas.',
                  color: Colors.orange,
                  onTap: _openNotification,
                ),

                // 5. Menu Profil.
                _buildMenuCard(
                  icon: Icons.person,
                  title: 'Profil',
                  subtitle: 'Lihat dan kelola informasi akun pengguna.',
                  color: Colors.teal,
                  onTap: _openProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget kartu ringkasan.
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Widget kartu menu.
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
