import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:store/core/config/app_config.dart';
import 'package:store/core/network/api_client.dart';
import 'package:store/core/network/api_exception.dart';
import 'package:store/core/realtime/catalog_events.dart';
import 'package:store/features/auth/application/admin_session.dart';
import 'package:store/features/catalog/data/store_repository.dart';
import 'package:store/features/catalog/domain/product.dart';

final testConfig = AppConfig(baseUrl: Uri.parse('http://localhost:8080'));

class TestEvents extends CatalogEvents {
  TestEvents() : super(testConfig);
  final source = StreamController<void>.broadcast(sync: true);
  @override
  Stream<void> get changes => source.stream;
  @override
  LiveStatus get status => LiveStatus.live;
  @override
  void start() {}
  @override
  void stop() {}
  void emit() => source.add(null);
  @override
  void dispose() {
    unawaited(source.close());
    super.dispose();
  }
}

Product sampleProduct(int id, {int brandId = 1}) => Product(
  id: id,
  brand: Brand(id: brandId, name: brandId == 1 ? 'Samsung' : 'Apple'),
  model: id.isEven ? 'iPhone 17 Pro' : 'Galaxy S26 Ultra',
  description: 'Diseñado para acompañarte todos los días. Una pantalla nítida, buen rendimiento y espacio para tus recuerdos.',
  price: 2500 + id * 100,
  stock: id % 5 == 0 ? 0 : 4,
  ram: 8,
  storage: 256,
  screen: 6.5,
  battery: 5000,
  os: 'Android',
  color: 'Negro',
  active: true,
  images: const [],
);

class FakeRepository extends StoreRepository {
  FakeRepository(AdminSession session)
    : super(
        ApiClient(
          testConfig,
          session,
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );
  List<Brand> brandItems = const [
    Brand(id: 1, name: 'Samsung'),
    Brand(id: 2, name: 'Apple'),
  ];
  List<Product> items = List.generate(
    18,
    (i) => sampleProduct(i + 1, brandId: i.isEven ? 1 : 2),
  );
  final seen = <CatalogQuery>[];
  Future<ProductPage> Function(CatalogQuery)? onProducts;
  Future<Product> Function(int)? onProduct;
  int saves = 0;

  @override
  Future<void> verifyCredentials(String authorization) async {
    if (authorization.isEmpty) {
      throw const ApiException('Credenciales incorrectas', statusCode: 401);
    }
  }

  @override
  Future<List<Brand>> brands() async => List.of(brandItems);
  @override
  Future<ProductPage> products(CatalogQuery query, {bool admin = false}) async {
    seen.add(query);
    if (onProducts != null) return onProducts!(query);
    var values = items
        .where(
          (p) =>
              (admin || p.active) &&
              (query.brandId == null || p.brand.id == query.brandId) &&
              p.model.toLowerCase().contains(query.text.toLowerCase()) &&
              (query.minPrice == null || p.price >= query.minPrice!) &&
              (query.maxPrice == null || p.price <= query.maxPrice!),
        )
        .toList();
    values.sort(
      (a, b) => query.sort == 'precio,asc'
          ? a.price.compareTo(b.price)
          : query.sort == 'precio,desc'
          ? b.price.compareTo(a.price)
          : b.id.compareTo(a.id),
    );
    final pages = (values.length / query.size).ceil();
    return ProductPage(
      items: values.skip(query.page * query.size).take(query.size).toList(),
      page: query.page,
      pages: pages,
      total: values.length,
    );
  }

  @override
  Future<Product> product(int id, {bool admin = false}) async {
    if (onProduct != null) return onProduct!(id);
    return items.firstWhere(
      (p) => p.id == id && (admin || p.active),
      orElse: () => throw const ApiException('No encontrado', statusCode: 404),
    );
  }

  @override
  Future<Product> saveProduct(Json data, {int? id}) async {
    saves++;
    final brand = brandItems.firstWhere((b) => b.id == data['marcaId']);
    final value = Product.fromJson({
      ...data,
      'id': id ?? 99,
      'marca': {'id': brand.id, 'nombre': brand.name},
      'imagenes': <dynamic>[],
    });
    items = [...items.where((p) => p.id != value.id), value];
    return value;
  }

  @override
  Future<void> deleteProduct(int id) async =>
      items = items.where((p) => p.id != id).toList();
  @override
  Future<Brand> saveBrand(String name, {int? id}) async {
    final value = Brand(id: id ?? 50, name: name);
    brandItems = [...brandItems.where((b) => b.id != value.id), value];
    return value;
  }

  @override
  Future<void> deleteBrand(int id) async =>
      brandItems = brandItems.where((b) => b.id != id).toList();
}
