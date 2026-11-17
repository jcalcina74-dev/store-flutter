import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/catalog_events.dart';
import '../data/store_repository.dart';
import '../domain/product.dart';

class DetailController extends ChangeNotifier {
  DetailController(this.repository, CatalogEvents events, this.id) {
    _subscription = events.changes.listen((_) => unawaited(refresh()));
  }
  final StoreRepository repository;
  final int id;
  late final StreamSubscription<void> _subscription;
  Product? product;
  bool loading = true, unavailable = false;
  String? error;
  bool _busy = false, _pending = false, _disposed = false;

  Future<void> refresh() async {
    _pending = true;
    if (_busy || _disposed) return;
    _busy = true;
    try {
      do {
        _pending = false;
        try {
          final value = await repository.product(id);
          if (_disposed) return;
          product = value;
          unavailable = false;
          error = null;
        } on ApiException catch (e) {
          if (_disposed) return;
          unavailable = e.notFound;
          if (unavailable) product = null;
          error = e.notFound ? null : e.message;
        } catch (_) {
          if (!_disposed) error = 'No se pudo cargar el celular.';
        }
      } while (_pending && !_disposed);
    } finally {
      _busy = false;
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
