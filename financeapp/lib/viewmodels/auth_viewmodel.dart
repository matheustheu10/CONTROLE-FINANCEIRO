import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  AuthStatus _status = AuthStatus.idle;
  String _errorMessage = '';
  UserModel? _currentUser;

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final existing = await _db.getUserByEmail(email.trim().toLowerCase());
      if (existing != null) {
        _status = AuthStatus.error;
        _errorMessage = 'Este e-mail já está cadastrado.';
        notifyListeners();
        return false;
      }

      final user = UserModel(
        id: _uuid.v4(),
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
      );

      final success = await _db.insertUser(user);
      if (success) {
        _currentUser = user;
        _status = AuthStatus.success;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Erro ao criar conta. Tente novamente.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro inesperado. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _db.getUserByEmail(email.trim().toLowerCase());
      if (user == null) {
        _status = AuthStatus.error;
        _errorMessage = 'E-mail não encontrado.';
        notifyListeners();
        return false;
      }

      if (user.passwordHash != _hashPassword(password)) {
        _status = AuthStatus.error;
        _errorMessage = 'Senha incorreta.';
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao fazer login. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _status = AuthStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }

  void resetStatus() {
    _status = AuthStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
