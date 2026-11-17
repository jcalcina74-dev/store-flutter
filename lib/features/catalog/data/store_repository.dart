import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../domain/product.dart';

class StoreRepository {
  StoreRepository(this.api);
  final ApiClient api;

  Future<void> verifyCredentials(String authorization) async {
    await api.request(
      'GET',
      '/api/admin/celulares',
      query: {'size': '1'},
      admin: true,
      authorization: authorization,
    );
  }

  Future<List<Brand>> brands() async {
    final result = await api.request('GET', '/api/catalogo/marcas') as List;
    return result.map((e) => Brand.fromJson(e as Json)).toList(growable: false);
  }

  Future<ProductPage> products(CatalogQuery query, {bool admin = false}) async {
    final result = await api.request(
      'GET',
      admin ? '/api/admin/celulares' : '/api/catalogo/celulares',
      query: query.toParameters(),
      admin: admin,
    );
    return ProductPage.fromJson(result as Json);
  }

  Future<Product> product(int id, {bool admin = false}) async {
    final root = admin ? '/api/admin/celulares' : '/api/catalogo/celulares';
    return Product.fromJson(
      await api.request('GET', '$root/$id', admin: admin) as Json,
    );
  }

  Future<Product> saveProduct(Json data, {int? id}) async {
    final path = id == null
        ? '/api/admin/celulares'
        : '/api/admin/celulares/$id';
    return Product.fromJson(
      await api.request(
        id == null ? 'POST' : 'PUT',
        path,
        body: data,
        admin: true,
      ) as Json,
    );
  }

  Future<void> deleteProduct(int id) async {
    await api.request('DELETE', '/api/admin/celulares/$id', admin: true);
  }

  Future<Brand> saveBrand(String name, {int? id}) async {
    final path = id == null ? '/api/admin/marcas' : '/api/admin/marcas/$id';
    return Brand.fromJson(
      await api.request(
        id == null ? 'POST' : 'PUT',
        path,
        body: {'nombre': name},
        admin: true,
      ) as Json,
    );
  }

  Future<void> deleteBrand(int id) async {
    await api.request('DELETE', '/api/admin/marcas/$id', admin: true);
  }

  Future<ProductImage> uploadImage(
    int productId,
    Uint8List bytes,
    String name,
    int order,
  ) async {
    return ProductImage.fromJson(
      await api.upload(
        '/api/admin/celulares/$productId/imagenes',
        bytes,
        name,
        order,
      ) as Json,
    );
  }

  Future<void> deleteImage(int productId, int imageId) async {
    await api.request(
      'DELETE',
      '/api/admin/celulares/$productId/imagenes/$imageId',
      admin: true,
    );
  }
}
