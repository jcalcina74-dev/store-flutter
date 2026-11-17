import 'package:flutter/material.dart';

import '../../application/catalog_controller.dart';

class CatalogPagination extends StatelessWidget {
  const CatalogPagination({required this.controller, super.key});
  final CatalogController controller;
  @override
  Widget build(BuildContext context) {
    if (controller.pages == 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          tooltip: 'Página anterior',
          onPressed: controller.query.page > 0
              ? () => controller.goToPage(controller.query.page - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Página ${controller.query.page + 1} de ${controller.pages}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Página siguiente',
          onPressed: controller.query.page + 1 < controller.pages
              ? () => controller.goToPage(controller.query.page + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
