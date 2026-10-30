import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/password_hasher.dart';

class UserRepository {
  final DatabaseService _database;

  UserRepository({DatabaseService? database})
    : _database = database ?? DatabaseService.instance;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String recoveryCode,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw ArgumentError('Nama wajib diisi.');
    }

    if (!_isValidEmail(cleanEmail)) {
      throw ArgumentError('Format email tidak valid.');
    }

    if (password.length < 8) {
      throw ArgumentError('Password minimal 8 karakter.');
    }

    final existing = await _database.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanEmail],
    );

    if (existing.isNotEmpty) {
      throw StateError('Email sudah terdaftar.');
    }

    final passwordHash = await PasswordHasher.hash(password);
    final recoveryHash = await PasswordHasher.hash(recoveryCode);

    final id = await _database.insert('users', {
      'name': cleanName,
      'email': cleanEmail,
      'password_hash': passwordHash,
      'recovery_code_hash': recoveryHash,
      'created_at': DateTime.now().toIso8601String(),
    });

    return UserModel(id: id, name: cleanName, email: cleanEmail);
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final rows = await _database.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanEmail],
    );

    if (rows.isEmpty) return null;

    final user = rows.first;
    final storedHash = user['password_hash'] as String;

    final valid = await PasswordHasher.verify(password, storedHash);

    if (!valid) return null;

    return UserModel.fromMap(user);
  }

  Future<String?> resetPassword({
    required String email,
    required String recoveryCode,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!_isValidEmail(cleanEmail)) {
      throw ArgumentError('Format email tidak valid.');
    }

    if (newPassword.length < 8) {
      throw ArgumentError('Password minimal 8 karakter.');
    }

    final rows = await _database.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanEmail],
    );

    if (rows.isEmpty) return null;

    final user = rows.first;
    final storedRecoveryHash = user['recovery_code_hash'] as String?;

    if (storedRecoveryHash == null) return null;

    final validRecoveryCode = await PasswordHasher.verify(
      recoveryCode.trim().toUpperCase(),
      storedRecoveryHash,
    );

    if (!validRecoveryCode) return null;

    // Kode lama diganti agar tidak dapat digunakan kembali.
    final newRecoveryCode = PasswordHasher.generateRecoveryCode();

    final newPasswordHash = await PasswordHasher.hash(newPassword);
    final newRecoveryHash = await PasswordHasher.hash(newRecoveryCode);

    await _database.update(
      'users',
      {'password_hash': newPasswordHash, 'recovery_code_hash': newRecoveryHash},
      where: 'id = ?',
      whereArgs: [user['id']],
    );

    return newRecoveryCode;
  }

  Future<UserModel?> getById(int id) async {
    final rows = await _database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rows.isEmpty) return null;

    return UserModel.fromMap(rows.first);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}
