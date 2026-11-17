import 'dart:convert';

import '../../../core/network/request_session.dart';

import 'package:flutter/foundation.dart';

import '../../catalog/data/store_repository.dart';
import '../../../core/network/api_exception.dart';

class AdminSession extends ChangeNotifier implements RequestSession {
  String? _authorization;
  String? _username;
  bool _busy = false;
  bool _disposed = false;
  String? _error;

  @override
  String? get authorization => _authorization;
  String? get username => _username;
  bool get authenticated => _authorization != null;
  bool get busy => _busy;
  String? get error => _error;

  Future<bool> signIn(
    StoreRepository repository,
    String user,
    String password,
  ) async {
    if (_busy || _disposed) return false;
    _busy = true;
    _error = null;
    if (!_disposed) notifyListeners();
    try {
      final encoded = base64Encode(utf8.encode('${user.trim()}:$password'));
      final authorization = 'Basic $encoded';
      await repository.verifyCredentials(authorization);
      if (_disposed) return false;
      _authorization = authorization;
      _username = user.trim();
      return true;
    } on ApiException catch (e) {
      _error = e.unauthorized ? 'Usuario o contraseña incorrectos.' : e.message;
      return false;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void signOut() {
    _authorization = null;
    _username = null;
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authorization = null;
    _username = null;
    super.dispose();
  }
}
