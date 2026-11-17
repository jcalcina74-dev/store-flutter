import 'package:intl/intl.dart';

typedef Json = Map<String, dynamic>;

class Brand {
  const Brand({required this.id, required this.name});
  factory Brand.fromJson(Json json) =>
      Brand(id: json['id'] as int, name: json['nombre'] as String);
  final int id;
  final String name;
}

class ProductImage {
  const ProductImage({
    required this.id,
    required this.url,
    required this.order,
  });
  factory ProductImage.fromJson(Json json) => ProductImage(
    id: json['id'] as int,
    url: json['url'] as String,
    order: json['orden'] as int,
  );
  final int id;
  final String url;
  final int order;
}

class Product {
  const Product({
    required this.id,
    required this.brand,
    required this.model,
    required this.description,
    required this.price,
    required this.stock,
    required this.ram,
    required this.storage,
    required this.screen,
    required this.battery,
    required this.os,
    required this.color,
    required this.active,
    required this.images,
  });
  factory Product.fromJson(Json json) => Product(
    id: json['id'] as int,
    brand: Brand.fromJson(json['marca'] as Json),
    model: json['modelo'] as String,
    description: json['descripcion'] as String? ?? '',
    price: (json['precio'] as num).toDouble(),
    stock: json['stock'] as int,
    ram: json['ramGb'] as int,
    storage: json['almacenamientoGb'] as int,
    screen: (json['pantallaPulgadas'] as num).toDouble(),
    battery: json['bateriaMah'] as int,
    os: json['sistemaOperativo'] as String,
    color: json['color'] as String,
    active: json['activo'] as bool,
    images: (json['imagenes'] as List)
        .map((i) => ProductImage.fromJson(i as Json))
        .toList(growable: false),
  );
  final int id;
  final Brand brand;
  final String model, description, os, color;
  final double price, screen;
  final int stock, ram, storage, battery;
  final bool active;
  final List<ProductImage> images;
  String get displayName =>
      model.isEmpty ? model : model[0].toUpperCase() + model.substring(1);
  String get formattedPrice => NumberFormat.currency(
    locale: 'es_BO',
    symbol: 'Bs',
    decimalDigits: 2,
  ).format(price);
  Product withImages(List<ProductImage> value) => Product(
    id: id,
    brand: brand,
    model: model,
    description: description,
    price: price,
    stock: stock,
    ram: ram,
    storage: storage,
    screen: screen,
    battery: battery,
    os: os,
    color: color,
    active: active,
    images: List.unmodifiable(value),
  );
}

class ProductPage {
  const ProductPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });
  factory ProductPage.fromJson(Json json) => ProductPage(
    items: (json['contenido'] as List)
        .map((p) => Product.fromJson(p as Json))
        .toList(growable: false),
    page: json['pagina'] as int,
    pages: json['totalPaginas'] as int,
    total: json['totalElementos'] as int,
  );
  final List<Product> items;
  final int page, pages, total;
}

class CatalogQuery {
  const CatalogQuery({
    this.page = 0,
    this.size = 12,
    this.text = '',
    this.sort = 'id,desc',
    this.brandId,
    this.minPrice,
    this.maxPrice,
  });
  final int page, size;
  final String text, sort;
  final int? brandId;
  final double? minPrice, maxPrice;
  bool get hasFilters =>
      text.isNotEmpty ||
      brandId != null ||
      minPrice != null ||
      maxPrice != null;
  Map<String, String> toParameters() => {
    'page': '$page',
    'size': '$size',
    'sort': sort,
    if (text.isNotEmpty) 'texto': text,
    if (brandId != null) 'marcaId': '$brandId',
    if (minPrice != null) 'precioMin': '$minPrice',
    if (maxPrice != null) 'precioMax': '$maxPrice',
  };
  CatalogQuery copyWith({
    int? page,
    String? text,
    String? sort,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    bool clearBrand = false,
    bool clearPrices = false,
  }) => CatalogQuery(
    page: page ?? this.page,
    size: size,
    text: text ?? this.text,
    sort: sort ?? this.sort,
    brandId: clearBrand ? null : brandId ?? this.brandId,
    minPrice: clearPrices ? null : minPrice ?? this.minPrice,
    maxPrice: clearPrices ? null : maxPrice ?? this.maxPrice,
  );
}
