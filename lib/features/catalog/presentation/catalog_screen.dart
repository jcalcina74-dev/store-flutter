import 'widgets/catalog_toolbar.dart';
import 'widgets/product_grid.dart';
import 'widgets/catalog_pagination.dart';
import 'widgets/catalog_hero.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/realtime/catalog_events.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/store_widgets.dart';
import '../application/catalog_controller.dart';
import '../data/store_repository.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final CatalogController controller;
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller = CatalogController(
      context.read<StoreRepository>(),
      context.read<CatalogEvents>(),
    );
    unawaited(controller.refresh());
  }

  @override
  void dispose() {
    controller.dispose();
    search.dispose();
    super.dispose();
  }

  void reset() {
    search.clear();
    controller.reset();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const StoreHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: PageWidth(
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const CatalogHero(),
                      const SizedBox(height: 32),
                      CatalogToolbar(
                        controller: controller,
                        search: search,
                        onFilter: () => _filters(context),
                      ),
                      const SizedBox(height: 18),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Todas las marcas'),
                              selected: controller.query.brandId == null,
                              onSelected: (_) => controller.selectBrand(null),
                            ),
                            for (final brand in controller.brands) ...[
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(brand.name.toUpperCase()),
                                selected: controller.query.brandId == brand.id,
                                onSelected: (_) =>
                                    controller.selectBrand(brand.id),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Explora el catálogo',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.loading
                                      ? 'Buscando tu próximo celular…'
                                      : '${controller.total} celulares para descubrir',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (controller.query.hasFilters)
                            TextButton(
                              onPressed: reset,
                              child: const Text('Limpiar filtros'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (controller.refreshing)
                        const LinearProgressIndicator(minHeight: 2),
                      if (controller.error != null &&
                          controller.products.isNotEmpty)
                        ErrorNotice(
                          controller.error!,
                          retry: controller.refresh,
                        ),
                      if (controller.loading)
                        const Padding(
                          padding: EdgeInsets.all(64),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (controller.error != null &&
                          controller.products.isEmpty)
                        EmptyState(
                          title: 'No pudimos cargar el catálogo',
                          message: controller.error!,
                          action: controller.refresh,
                        )
                      else if (controller.products.isEmpty)
                        EmptyState(
                          title: controller.query.hasFilters
                              ? 'No encontramos coincidencias'
                              : 'Pronto tendremos novedades',
                          message: controller.query.hasFilters
                              ? 'Prueba con otra marca o ajusta los filtros de búsqueda.'
                              : 'Los celulares aparecerán aquí cuando estén disponibles.',
                          action: controller.query.hasFilters ? reset : null,
                          label: 'Ver todo el catálogo',
                        )
                      else ...[
                        const SizedBox(height: 8),
                        ProductGrid(products: controller.products),
                        const SizedBox(height: 22),
                        CatalogPagination(controller: controller),
                      ],
                      const SizedBox(height: 38),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Text(
                              'NOVA',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            Spacer(),
                            Flexible(
                              child: Text(
                                'Encuentra tu próxima conexión.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _filters(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PriceFilterSheet(controller: controller),
    );
  }
}

class PriceFilterSheet extends StatefulWidget {
  const PriceFilterSheet({required this.controller, super.key});
  final CatalogController controller;
  @override
  State<PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<PriceFilterSheet> {
  late final minimum = TextEditingController(
    text: widget.controller.query.minPrice?.toStringAsFixed(0) ?? '',
  );
  late final maximum = TextEditingController(
    text: widget.controller.query.maxPrice?.toStringAsFixed(0) ?? '',
  );
  final keyForm = GlobalKey<FormState>();
  @override
  void dispose() {
    minimum.dispose();
    maximum.dispose();
    super.dispose();
  }

  String? validate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final n = double.tryParse(s.replaceAll(',', '.'));
    return n == null || !n.isFinite || n < 0 ? 'Precio no válido' : null;
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: keyForm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encuentra el indicado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Filtra por precio en bolivianos.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: minimum,
              decoration: const InputDecoration(
                labelText: 'Desde',
                prefixText: 'Bs ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: validate,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: maximum,
              decoration: const InputDecoration(
                labelText: 'Hasta',
                prefixText: 'Bs ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (s) {
                final invalid = validate(s);
                if (invalid != null) return invalid;
                final min = double.tryParse(minimum.text.replaceAll(',', '.'));
                final max = double.tryParse((s ?? '').replaceAll(',', '.'));
                return min != null && max != null && max < min
                    ? 'Debe ser mayor al mínimo'
                    : null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!keyForm.currentState!.validate()) return;
                  widget.controller.prices(
                    double.tryParse(minimum.text.replaceAll(',', '.')),
                    double.tryParse(maximum.text.replaceAll(',', '.')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Aplicar filtros'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  widget.controller.prices(null, null);
                  Navigator.pop(context);
                },
                child: const Text('Quitar rango de precio'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
