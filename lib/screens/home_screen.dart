import 'package:flutter/material.dart';

import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Halaman $feature akan dibuat selanjutnya.')),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = MaterialLocalizations.of(context).formatFullDate(now);

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, Pengguna!',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(date, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),

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
                      'Pantau konsumsi air minum dan asupan kalori '
                      'untuk membantu menjaga pola hidup sehat.',
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

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.water_drop,
                      title: 'Hidrasi',
                      value: '0 ml',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.local_fire_department,
                      title: 'Kalori',
                      value: '0 kkal',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              const Text(
                'Menu Utama',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              _buildMenuCard(
                context,
                icon: Icons.water_drop,
                title: 'Hidrasi',
                subtitle: 'Hitung kebutuhan air dan atur jadwal minum.',
                color: Colors.blue,
              ),
              _buildMenuCard(
                context,
                icon: Icons.restaurant,
                title: 'Nutrisi',
                subtitle: 'Catat makanan dan hitung kalori harian.',
                color: Colors.green,
              ),
              _buildMenuCard(
                context,
                icon: Icons.bar_chart,
                title: 'Dashboard',
                subtitle: 'Pantau grafik perkembangan harian dan mingguan.',
                color: Colors.purple,
              ),
              _buildMenuCard(
                context,
                icon: Icons.notifications_active,
                title: 'Notifikasi',
                subtitle: 'Atur pengingat jadwal minum dan makan.',
                color: Colors.orange,
              ),
              _buildMenuCard(
                context,
                icon: Icons.person,
                title: 'Profil',
                subtitle: 'Kelola nama, usia, tinggi, dan berat badan.',
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
        onTap: () => _showComingSoon(context, title),
      ),
    );
  }
}
