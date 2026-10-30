

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/nutrition_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _portionController =
      TextEditingController(text: '100');
  final TextEditingController _caloriesController =
      TextEditingController();

  String _selectedMeal = 'Sarapan';
  List<Map<String, Object?>> _foods = [];
  double _totalCalories = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _mealTypes = [
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan',
  ];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final foods =
          await NutritionService.instance.getTodayFoods(user.id);
      final calories =
          await NutritionService.instance.getTodayCalories(user.id);

      if (!mounted) return;

      setState(() {
        _foods = foods;
        _totalCalories = calories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Gagal memuat data nutrisi: $e');
    }
  }

  Future<void> _saveFood() async {
    if (_isSaving) return;

    final name = _foodController.text.trim();
    final portion = double.tryParse(_portionController.text);
    final calories = double.tryParse(_caloriesController.text);

    if (name.isEmpty) {
      _showMessage('Masukkan nama makanan.');
      return;
    }

    if (portion == null || portion <= 0) {
      _showMessage('Masukkan porsi makanan yang valid.');
      return;
    }

    if (calories == null || calories < 0) {
      _showMessage('Masukkan jumlah kalori yang valid.');
      return;
    }

    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await NutritionService.instance.saveFood(
        userId: user.id,
        foodName: name,
        portionGrams: portion,
        calories: calories,
        mealType: _selectedMeal,
      );

      _foodController.clear();
      _portionController.text = '100';
      _caloriesController.clear();

      await _loadFoods();

      if (!mounted) return;
      _showMessage('Makanan berhasil disimpan.');
    } catch (e) {
      _showMessage('Gagal menyimpan makanan: $e');
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
    _foodController.dispose();
    _portionController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kalkulator Nutrisi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loadFoods,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadFoods,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Asupan Kalori Hari Ini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.green,
                              size: 45,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_totalCalories.toStringAsFixed(0)} kkal',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Total kalori hari ini'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Tambah Makanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedMeal,
                      decoration: const InputDecoration(
                        labelText: 'Jadwal makan',
                        border: OutlineInputBorder(),
                      ),
                      items: _mealTypes.map((meal) {
                        return DropdownMenuItem(
                          value: meal,
                          child: Text(meal),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMeal = value);
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _foodController,
                      decoration: const InputDecoration(
                        labelText: 'Nama makanan',
                        hintText: 'Contoh: Nasi goreng',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _portionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Porsi makanan (gram)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Kalori (kkal)',
                        hintText: 'Contoh: 250',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveFood,
                        icon: const Icon(Icons.save),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Makanan',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Riwayat Makanan Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_foods.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text('Belum ada makanan yang dicatat.'),
                          ),
                        ),
                      )
                    else
                      ..._foods.map((food) {
                        final name = food['food_name']?.toString() ?? '';
                        final portion =
                            (food['portion_grams'] as num?)?.toDouble() ?? 0;
                        final calories =
                            (food['calories'] as num?)?.toDouble() ?? 0;
                        final time =
                            food['consumed_at']?.toString() ?? '';

                        final dateTime = DateTime.tryParse(time);
                        final timeLabel = dateTime == null
                            ? ''
                            : '${dateTime.hour.toString().padLeft(2, '0')}:'
                                '${dateTime.minute.toString().padLeft(2, '0')}';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.restaurant),
                            ),
                            title: Text(name),
                            subtitle: Text(
                              '$portion gram • $timeLabel',
                            ),
                            trailing: Text(
                              '${calories.toStringAsFixed(0)} kkal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
