import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile_model.dart';
import '../providers/auth_provider.dart';
import '../repositories/profile_repository.dart';
import 'about_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();

  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _gender;
  String? _activityLevel;

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final profile = await _profileRepository.getByUserId(user.id);

      if (!mounted) return;

      if (profile != null) {
        _ageController.text = profile.age?.toString() ?? '';
        _heightController.text = profile.heightCm?.toString() ?? '';
        _weightController.text = profile.weightKg?.toString() ?? '';
        _gender = profile.gender;
        _activityLevel = profile.activityLevel;
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Gagal memuat profil: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    if (_gender == null || _activityLevel == null) {
      _showMessage('Pilih jenis kelamin dan tingkat aktivitas.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = ProfileModel(
        userId: user.id,
        age: int.parse(_ageController.text.trim()),
        heightCm: double.parse(
          _heightController.text.trim().replaceAll(',', '.'),
        ),
        weightKg: double.parse(
          _weightController.text.trim().replaceAll(',', '.'),
        ),
        gender: _gender,
        activityLevel: _activityLevel,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _profileRepository.save(profile);

      if (!mounted) return;

      setState(() => _isEditing = false);
      _showMessage('Profil berhasil disimpan.');
    } catch (e) {
      if (mounted) {
        _showMessage('Gagal menyimpan profil: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<AuthProvider>().logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Gagal logout: $e');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required double maxValue,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi.';
        }

        final number = double.tryParse(value.trim().replaceAll(',', '.'));

        if (number == null || number <= 0 || number > maxValue) {
          return 'Masukkan $label yang valid.';
        }

        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: _isEditing ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Silakan login untuk melihat profil.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.person, size: 55),
                ),
                const SizedBox(height: 16),

                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 28),
                const Text(
                  'Data Pribadi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Umur',
                  controller: _ageController,
                  suffix: 'tahun',
                  maxValue: 120,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  label: 'Tinggi Badan',
                  controller: _heightController,
                  suffix: 'cm',
                  maxValue: 300,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  label: 'Berat Badan',
                  controller: _weightController,
                  suffix: 'kg',
                  maxValue: 500,
                ),
                const SizedBox(height: 14),

                _buildDropdown(
                  label: 'Jenis Kelamin',
                  value: _gender,
                  options: const ['Laki-laki', 'Perempuan'],
                  onChanged: (value) {
                    setState(() => _gender = value);
                  },
                ),
                const SizedBox(height: 14),

                _buildDropdown(
                  label: 'Tingkat Aktivitas',
                  value: _activityLevel,
                  options: const [
                    'Rendah',
                    'Ringan',
                    'Sedang',
                    'Tinggi',
                    'Sangat Tinggi',
                  ],
                  onChanged: (value) {
                    setState(() => _activityLevel = value);
                  },
                ),

                const SizedBox(height: 22),

                if (!_isEditing)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profil'),
                  )
                else ...[
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: const Icon(Icons.save),
                    label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Profil'),
                  ),
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            _loadProfile();
                            setState(() => _isEditing = false);
                          },
                    child: const Text('Batal'),
                  ),
                ],

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),

                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 12),

                const Text(
                  '© 2026 Pelacak Hidrasi dan Nutrisi',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 6),

                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      },
                      child: const Text('Rahmat Ismail'),
                    ),
                    const Text(
                      '&',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      },
                      child: const Text('Ganeza Pratama'),
                    ),
                  ],
                ),
                const Text(
                  'Universitas Negeri Padang',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
