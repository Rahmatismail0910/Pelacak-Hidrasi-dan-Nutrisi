import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/password_hasher.dart';
import '../services/session_services.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final SessionService _sessionService;

  AuthProvider({UserRepository? userRepository, SessionService? sessionService})
    : _userRepository = userRepository ?? UserRepository(),
      _sessionService = sessionService ?? SessionService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _recoveryCode;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  // Ditampilkan setelah registrasi atau reset password berhasil.
  String? get recoveryCode => _recoveryCode;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;
      _recoveryCode = null;

      final generatedCode = PasswordHasher.generateRecoveryCode();

      final user = await _userRepository.register(
        name: name,
        email: email,
        password: password,
        recoveryCode: generatedCode,
      );

      await _sessionService.saveSession(user.id);

      _currentUser = user;
      _recoveryCode = generatedCode;

      return true;
    } catch (e) {
      _errorMessage = _readableError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);

    try {
      _errorMessage = null;
      _recoveryCode = null;

      final user = await _userRepository.login(
        email: email,
        password: password,
      );

      if (user == null) {
        _errorMessage = 'Email atau password salah.';
        return false;
      }

      await _sessionService.saveSession(user.id);
      _currentUser = user;

      return true;
    } catch (e) {
      _errorMessage = _readableError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String recoveryCode,
    required String newPassword,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;
      _recoveryCode = null;

      final newCode = await _userRepository.resetPassword(
        email: email,
        recoveryCode: recoveryCode,
        newPassword: newPassword,
      );

      if (newCode == null) {
        _errorMessage = 'Email atau kode pemulihan tidak sesuai.';
        return false;
      }

      _recoveryCode = newCode;
      return true;
    } catch (e) {
      _errorMessage = _readableError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restoreSession() async {
    _setLoading(true);

    try {
      final userId = await _sessionService.getUserId();

      if (userId == null) {
        _currentUser = null;
        return;
      }

      _currentUser = await _userRepository.getById(userId);

      if (_currentUser == null) {
        await _sessionService.clearSession();
      }
    } catch (e) {
      _errorMessage = _readableError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _sessionService.clearSession();
      _currentUser = null;
      _recoveryCode = null;
      _errorMessage = null;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearRecoveryCode() {
    _recoveryCode = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _readableError(Object error) {
    final message = error.toString();

    if (message.contains('Email sudah terdaftar')) {
      return 'Email tersebut sudah digunakan.';
    }

    if (message.contains('Format email tidak valid')) {
      return 'Masukkan alamat email yang valid.';
    }

    if (message.contains('Password minimal')) {
      return 'Password minimal 8 karakter.';
    }

    if (message.contains('Nama wajib diisi')) {
      return 'Nama wajib diisi.';
    }

    return 'Terjadi kesalahan. Silakan coba kembali.';
  }
}
