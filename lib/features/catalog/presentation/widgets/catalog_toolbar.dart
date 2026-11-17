import 'package:flutter/material.dart';

import '../../application/catalog_controller.dart';

class CatalogToolbar extends StatelessWidget {
  const CatalogToolbar({
    required this.controller,
    required this.search,
    this.onFilter,
    super.key,
  });
  final CatalogController controller;
  final TextEditingController search;
  final VoidCallback? onFilter;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final field = TextField(
        controller: search,
        onChanged: controller.search,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar un modelo…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            tooltip: 'Borrar búsqueda',
            onPressed: () {
              search.clear();
              controller.search('');
            },
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
      );
      final sort = DropdownButtonFormField<String>(
        key: ValueKey(controller.query.sort),
        initialValue: controller.query.sort,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.sort_rounded)),
        items: const [
          DropdownMenuItem(value: 'id,desc', child: Text('Más recientes')),
          DropdownMenuItem(value: 'precio,asc', child: Text('Menor precio')),
          DropdownMenuItem(value: 'precio,desc', child: Text('Mayor precio')),
          DropdownMenuItem(value: 'modelo,asc', child: Text('Nombre A–Z')),
        ],
        onChanged: (s) {
          if (s != null) controller.sort(s);
        },
      );
      final filter = IconButton.filledTonal(
        onPressed: onFilter,
        tooltip: 'Filtrar por precio',
        icon: const Icon(Icons.tune_rounded),
      );
      if (constraints.maxWidth < 640) {
        return Column(
          children: [
            field,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: sort),
                if (onFilter != null) ...[const SizedBox(width: 12), filter],
              ],
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: field),
          const SizedBox(width: 14),
          SizedBox(width: 210, child: sort),
          if (onFilter != null) ...[const SizedBox(width: 12), filter],
        ],
      );
    },
  );
}
