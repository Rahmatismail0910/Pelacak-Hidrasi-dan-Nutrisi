
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/hydration_service.dart';
import '../providers/auth_provider.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  final TextEditingController _targetController =
      TextEditingController(text: '2000');

  final TextEditingController _amountController =
      TextEditingController(text: '250');

  int _dailyTarget = 2000;
  int _totalDrunk = 0;
  int _savedTotal = 0;

  bool _isSaving = false;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _schedule = [
    {'time': '07:00', 'amount': 250, 'completed': false},
    {'time': '09:00', 'amount': 250, 'completed': false},
    {'time': '11:00', 'amount': 250, 'completed': false},
    {'time': '13:00', 'amount': 250, 'completed': false},
    {'time': '15:00', 'amount': 250, 'completed': false},
    {'time': '17:00', 'amount': 250, 'completed': false},
    {'time': '19:00', 'amount': 250, 'completed': false},
    {'time': '21:00', 'amount': 250, 'completed': false},
  ];

  double get _progress => _dailyTarget > 0
      ? (_totalDrunk / _dailyTarget).clamp(0.0, 1.0)
      : 0;

  @override
  void initState() {
    super.initState();
    _loadHydration();
  }

  Future<void> _loadHydration() async {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final summary =
          await HydrationService.instance.getTodaySummary(user.id);

      if (!mounted) return;

      final total = (summary['total_water_ml'] as num?)?.toInt() ?? 0;
      final target = (summary['target_water_ml'] as num?)?.toInt() ?? 2000;

      setState(() {
        _totalDrunk = total;
        _savedTotal = total;
        _dailyTarget = target > 0 ? target : 2000;
        _targetController.text = _dailyTarget.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Gagal memuat data hidrasi: $e');
    }
  }

  void _addWater() {
    final amount = int.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      _showMessage('Masukkan jumlah air yang valid.');
      return;
    }

    setState(() {
      _totalDrunk += amount;
    });

    _showMessage('$amount ml air berhasil dicatat. Tekan Simpan Hidrasi.');
  }

  void _updateTarget() {
    final target = int.tryParse(_targetController.text);

    if (target == null || target <= 0) {
      _showMessage('Masukkan target air yang valid.');
      return;
    }

    setState(() {
      _dailyTarget = target;
    });

    _showMessage('Target diperbarui. Tekan Simpan Hidrasi untuk menyimpan.');
  }

  void _toggleSchedule(int index, bool? value) {
    final completed = value ?? false;
    final item = _schedule[index];
    final amount = item['amount'] as int;

    setState(() {
      if (item['completed'] == completed) return;

      item['completed'] = completed;
      _totalDrunk += completed ? amount : -amount;

      if (_totalDrunk < 0) {
        _totalDrunk = 0;
      }
    });
  }

  Future<void> _saveHydration() async {
    if (_isSaving) return;

    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    final unsavedAmount = _totalDrunk - _savedTotal;

    if (unsavedAmount < 0) {
      _showMessage(
        'Jumlah konsumsi lebih kecil dari data tersimpan. '
        'Data lama tidak akan dihapus.',
      );
      return;
    }

    if (unsavedAmount == 0 && _dailyTarget == 0) {
      _showMessage('Tidak ada data baru untuk disimpan.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await HydrationService.instance.saveHydration(
        userId: user.id,
        amountMl: unsavedAmount,
        targetMl: _dailyTarget,
      );

      if (!mounted) return;

      setState(() {
        _savedTotal = _totalDrunk;
      });

      _showMessage('Data hidrasi berhasil disimpan.');
    } catch (e) {
      _showMessage('Gagal menyimpan data hidrasi: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kalkulator Hidrasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konsumsi Air Hari Ini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                              size: 45,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$_totalDrunk ml',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('dari $_dailyTarget ml'),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: _progress,
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.blue,
                              backgroundColor: Colors.blue.shade100,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_progress * 100).toStringAsFixed(0)}% tercapai',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum disimpan: ${_totalDrunk - _savedTotal} ml',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Target Minum Harian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _targetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Target air (ml)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _updateTarget,
                          child: const Text('Perbarui'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Catat Air Minum',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah air (ml)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _addWater,
                          icon: const Icon(Icons.add),
                          label: const Text('Catat'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Jadwal Minum Air',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...List.generate(_schedule.length, (index) {
                      final item = _schedule[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: item['completed'] as bool,
                          onChanged: (value) =>
                              _toggleSchedule(index, value),
                          secondary: const Icon(
                            Icons.water_drop,
                            color: Colors.blue,
                          ),
                          title: Text('${item['time']}'),
                          subtitle: Text('${item['amount']} ml air'),
                          controlAffinity:
                              ListTileControlAffinity.trailing,
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveHydration,
                        icon: const Icon(Icons.save),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Hidrasi',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
