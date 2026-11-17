import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../catalog/data/store_repository.dart';
import '../../catalog/domain/product.dart';

class ProductEditorController extends ChangeNotifier {
  ProductEditorController(this.repository, this.id);
  final StoreRepository repository;
  int? id;
  Product? product;
  List<Brand> brands = const [];
  bool loading = true, saving = false, uploading = false, _disposed = false;
  String? error;
  bool get busy => loading || saving || uploading;

  Future<void> load() async {
    loading = true;
    _notify();
    try {
      brands = await repository.brands();
      if (id != null) product = await repository.product(id!, admin: true);
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<Product?> save(Json data) async {
    if (busy) return null;
    saving = true;
    error = null;
    _notify();
    try {
      final result = await repository.saveProduct(data, id: id);
      product = result;
      id = result.id;
      return result;
    } on ApiException catch (e) {
      error = e.message;
      return null;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<bool> upload(Uint8List bytes, String name) async {
    if (busy || product == null) return false;
    uploading = true;
    error = null;
    _notify();
    try {
      final images = product!.images;
      final order =
          images.fold<int>(
            -1,
            (max, image) => image.order > max ? image.order : max,
          ) +
          1;
      final image = await repository.uploadImage(id!, bytes, name, order);
      product = product!.withImages([...images, image]);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      uploading = false;
      _notify();
    }
  }

  Future<bool> deleteImage(int imageId) async {
    if (busy || product == null) return false;
    uploading = true;
    error = null;
    _notify();
    try {
      await repository.deleteImage(id!, imageId);
      product = product!.withImages(
        product!.images.where((i) => i.id != imageId).toList(),
      );
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      uploading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
