import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/store_widgets.dart';
import '../../domain/product.dart';

class ProductGallery extends StatefulWidget {
  const ProductGallery({required this.product, this.admin = false, super.key});
  final Product product;
  final bool admin;
  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  int selected = 0;
  @override
  void didUpdateWidget(covariant ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selected >= widget.product.images.length) selected = 0;
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images;
    final count = images.length;
    return Column(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFFEEF2F8),
                    padding: const EdgeInsets.all(32),
                    child: ProductPhoto(
                      product: widget.product,
                      image: count == 0 ? null : images[selected],
                      admin: widget.admin,
                    ),
                  ),
                ),
                if (count > 1) ...[
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filledTonal(
                        tooltip: 'Imagen anterior',
                        onPressed: () => setState(
                          () => selected = (selected - 1 + count) % count,
                        ),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filledTonal(
                        tooltip: 'Siguiente imagen',
                        onPressed: () =>
                            setState(() => selected = (selected + 1) % count),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: StatusPill(
                      '${selected + 1} / $count',
                      positive: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (count > 1)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < count; index++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => setState(() => selected = index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 68,
                          height: 76,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected == index
                                  ? AppColors.blue
                                  : AppColors.line,
                              width: selected == index ? 2 : 1,
                            ),
                          ),
                          child: ProductPhoto(
                            product: widget.product,
                            image: images[index],
                            admin: widget.admin,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
