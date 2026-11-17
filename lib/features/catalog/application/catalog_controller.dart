import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/catalog_events.dart';
import '../data/store_repository.dart';
import '../domain/product.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(
    this.repository,
    CatalogEvents events, {
    this.admin = false,
  }) {
    _subscription = events.changes.listen((_) => unawaited(refresh()));
  }
  final StoreRepository repository;
  final bool admin;
  late final StreamSubscription<void> _subscription;
  CatalogQuery _query = const CatalogQuery();
  CatalogQuery get query => _query;
  List<Product> products = const [];
  List<Brand> brands = const [];
  int total = 0, pages = 0;
  bool loading = true, refreshing = false;
  String? error;
  bool _busy = false, _pending = false, _disposed = false;
  Timer? _searchTimer;

  Future<void> refresh() async {
    if (_disposed) return;
    _pending = true;
    if (_busy) return;
    _busy = true;
    refreshing = true;
    notifyListeners();
    try {
      do {
        _pending = false;
        final requested = _query;
        try {
          final result = await Future.wait<Object>([
            repository.products(requested, admin: admin),
            repository.brands(),
          ]);
          if (_disposed) return;
          if (!identical(requested, _query)) {
            _pending = true;
            continue;
          }
          final page = result[0] as ProductPage;
          final updatedBrands = result[1] as List<Brand>;
          if (requested.brandId != null &&
              !updatedBrands.any((b) => b.id == requested.brandId)) {
            _query = requested.copyWith(clearBrand: true, page: 0);
            _pending = true;
            continue;
          }
          if (requested.page > 0 && requested.page >= page.pages) {
            _query = requested.copyWith(
              page: page.pages > 0 ? page.pages - 1 : 0,
            );
            _pending = true;
            continue;
          }
          products = page.items;
          brands = updatedBrands;
          total = page.total;
          pages = page.pages;
          error = null;
        } on ApiException catch (e) {
          if (!_disposed && identical(requested, _query)) error = e.message;
        } catch (_) {
          if (!_disposed && identical(requested, _query)) {
            error = 'No se pudo cargar el catálogo.';
          }
        }
      } while (_pending && !_disposed);
    } finally {
      _busy = false;
      if (!_disposed) {
        loading = false;
        refreshing = false;
        notifyListeners();
      }
    }
  }

  void search(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      _query = _query.copyWith(text: value.trim(), page: 0);
      unawaited(refresh());
    });
  }

  void selectBrand(int? id) {
    _query = _query.copyWith(brandId: id, clearBrand: id == null, page: 0);
    unawaited(refresh());
  }

  void sort(String value) {
    _query = _query.copyWith(sort: value, page: 0);
    unawaited(refresh());
  }

  void prices(double? min, double? max) {
    _query = _query
        .copyWith(clearPrices: true, page: 0)
        .copyWith(minPrice: min, maxPrice: max);
    unawaited(refresh());
  }

  void goToPage(int page) {
    if (page < 0 || (pages > 0 && page >= pages)) return;
    _query = _query.copyWith(page: page);
    unawaited(refresh());
  }

  void reset() {
    _searchTimer?.cancel();
    _query = const CatalogQuery();
    unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    _searchTimer?.cancel();
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
