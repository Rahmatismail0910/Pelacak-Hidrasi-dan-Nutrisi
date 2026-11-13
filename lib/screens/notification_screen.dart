
import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../services/notification_services.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  ScheduleModel _settings = const ScheduleModel();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      await NotificationServices.instance.initialize();

      final settings =
          await NotificationServices.instance.loadSettings();

      if (!mounted) return;

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Gagal memuat pengaturan notifikasi.');
    }
  }

  String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime({
    required int currentMinutes,
    required ValueChanged<int> onChanged,
  }) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentMinutes ~/ 60,
        minute: currentMinutes % 60,
      ),
    );

    if (selectedTime == null) return;

    final minutes =
        selectedTime.hour * 60 + selectedTime.minute;

    onChanged(minutes);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    if (_settings.waterEnabled &&
        _settings.waterStartMinutes >=
            _settings.waterEndMinutes) {
      _showMessage(
        'Jam mulai pengingat minum harus lebih awal dari jam selesai.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success =
          await NotificationServices.instance.saveSettings(_settings);

      if (!mounted) return;

      if (success) {
        _showMessage('Pengaturan notifikasi berhasil disimpan.');
      } else {
        _showMessage(
          'Izin notifikasi belum diberikan. Aktifkan izin notifikasi di pengaturan HP.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal menyimpan pengaturan notifikasi.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildTimeTile({
    required String title,
    required int minutes,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.access_time, size: 18),
        label: Text(_formatTime(minutes)),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Notifikasi')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Colors.blue,
                    size: 30,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jaga Pola Hidup Sehat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Atur pengingat minum air dan jadwal makan '
                          'agar aktivitas harian lebih teratur.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              title: 'Pengingat Minum Air',
              icon: Icons.water_drop,
              color: Colors.blue,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktifkan pengingat minum'),
                    value: _settings.waterEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          waterEnabled: value,
                        );
                      });
                    },
                  ),
                  if (_settings.waterEnabled) ...[
                    const Divider(),
                    _buildTimeTile(
                      title: 'Mulai pengingat',
                      minutes: _settings.waterStartMinutes,
                      onTap: () => _selectTime(
                        currentMinutes:
                            _settings.waterStartMinutes,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(
                              waterStartMinutes: value,
                            );
                          });
                        },
                      ),
                    ),
                    _buildTimeTile(
                      title: 'Akhiri pengingat',
                      minutes: _settings.waterEndMinutes,
                      onTap: () => _selectTime(
                        currentMinutes: _settings.waterEndMinutes,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(
                              waterEndMinutes: value,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _settings.waterIntervalMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Interval pengingat',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 30,
                          child: Text('30 menit'),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('60 menit'),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text('90 menit'),
                        ),
                        DropdownMenuItem(
                          value: 120,
                          child: Text('120 menit'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _settings = _settings.copyWith(
                            waterIntervalMinutes: value,
                          );
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            _buildSection(
              title: 'Pengingat Jadwal Makan',
              icon: Icons.restaurant,
              color: Colors.green,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pengingat sarapan'),
                    value: _settings.breakfastEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          breakfastEnabled: value,
                        );
                      });
                    },
                  ),
                  if (_settings.breakfastEnabled)
                    _buildTimeTile(
                      title: 'Waktu sarapan',
                      minutes: _settings.breakfastMinutes,
                      onTap: () => _selectTime(
                        currentMinutes:
                            _settings.breakfastMinutes,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(
                              breakfastMinutes: value,
                            );
                          });
                        },
                      ),
                    ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pengingat makan siang'),
                    value: _settings.lunchEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          lunchEnabled: value,
                        );
                      });
                    },
                  ),
                  if (_settings.lunchEnabled)
                    _buildTimeTile(
                      title: 'Waktu makan siang',
                      minutes: _settings.lunchMinutes,
                      onTap: () => _selectTime(
                        currentMinutes: _settings.lunchMinutes,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(
                              lunchMinutes: value,
                            );
                          });
                        },
                      ),
                    ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pengingat makan malam'),
                    value: _settings.dinnerEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          dinnerEnabled: value,
                        );
                      });
                    },
                  ),
                  if (_settings.dinnerEnabled)
                    _buildTimeTile(
                      title: 'Waktu makan malam',
                      minutes: _settings.dinnerMinutes,
                      onTap: () => _selectTime(
                        currentMinutes: _settings.dinnerMinutes,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(
                              dinnerMinutes: value,
                            );
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Menyimpan...'
                      : 'Simpan Pengaturan',
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

