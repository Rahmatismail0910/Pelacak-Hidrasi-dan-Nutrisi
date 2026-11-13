
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.water_drop,
              size: 75,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),

            const Text(
              'Pelacak Hidrasi dan Nutrisi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Pelacak Hidrasi dan Nutrisi merupakan aplikasi '
              'kesehatan dan gaya hidup yang dirancang untuk '
              'membantu pengguna memantau kebutuhan cairan dan '
              'asupan nutrisi harian. Aplikasi ini menyediakan '
              'kalkulator hidrasi, kalkulator nutrisi, pengingat '
              'minum dan makan, serta grafik pemantauan mingguan '
              'dan bulanan. Melalui data profil pengguna, aplikasi '
              'membantu menyesuaikan rekomendasi kebutuhan harian '
              'agar pengguna dapat membangun pola hidup yang '
              'lebih sehat dan teratur.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 15, height: 1.6),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Tentang Pembuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _authorCard(
              name: 'Rahmat Ismail',
              nim: '24343068',
            ),
            const SizedBox(height: 14),

            _authorCard(
              name: 'Ganeza Pratama',
              nim: '24343116',
            ),

            const SizedBox(height: 20),
            const Text(
              'Universitas Negeri Padang',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              '© 2026 Pelacak Hidrasi dan Nutrisi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _authorCard({
    required String name,
    required String nim,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('NIM: $nim'),
      ),
    );
  }
}
