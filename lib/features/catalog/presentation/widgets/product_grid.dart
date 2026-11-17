import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/store_widgets.dart';
import '../../domain/product.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({required this.products, super.key});
  final List<Product> products;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = scale > 1.5
          ? (w > 800 ? 2 : 1)
          : (w < 335
                ? 1
                : w < 650
                ? 2
                : w < 960
                ? 3
                : 4);
      final cardWidth = (w - 16 * (columns - 1)) / columns;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: cardWidth * .8 + 178 * scale,
        ),
        itemBuilder: (_, index) => ProductCard(product: products[index]),
      );
    },
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});
  final Product product;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/celular/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF0F3F9),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: ProductPhoto(product: product),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${product.ram} GB RAM · ${product.storage} GB',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Text(
                  product.formattedPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    letterSpacing: -.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                StatusPill(
                  product.stock > 0 ? 'Disponible' : 'Agotado',
                  positive: product.stock > 0,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
