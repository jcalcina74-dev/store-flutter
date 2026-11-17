import 'widgets/product_gallery.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/realtime/catalog_events.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/store_widgets.dart';
import '../application/detail_controller.dart';
import '../data/store_repository.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({required this.id, super.key});
  final int id;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final DetailController controller;
  @override
  void initState() {
    super.initState();
    controller = DetailController(
      context.read<StoreRepository>(),
      context.read<CatalogEvents>(),
      widget.id,
    );
    unawaited(controller.refresh());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const StoreHeader(back: true),
        Expanded(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.unavailable) {
                return EmptyState(
                  title: 'Este celular ya no está disponible',
                  message: 'El catálogo cambió. Puedes seguir explorando otros modelos.',
                  icon: Icons.inventory_2_outlined,
                  action: () => context.go('/'),
                  label: 'Volver al catálogo',
                );
              }
              if (controller.product == null) {
                return EmptyState(
                  title: 'No pudimos abrir el detalle',
                  message: controller.error ?? 'Inténtalo nuevamente.',
                  action: controller.refresh,
                );
              }
              final p = controller.product!;
              return SingleChildScrollView(
                child: PageWidth(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.error != null)
                          ErrorNotice(
                            controller.error!,
                            retry: controller.refresh,
                          ),
                        Text(
                          'CATÁLOGO  /  ${p.brand.name.toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 22),
                        LayoutBuilder(
                          builder: (context, c) {
                            final info = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.brand.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 12,
                                    letterSpacing: 1.6,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  p.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge,
                                ),
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Chip(label: Text('${p.ram} GB RAM')),
                                    Chip(label: Text('${p.storage} GB')),
                                    Chip(label: Text(p.color)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 23),
                                Text(
                                  p.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                StatusPill(
                                  p.stock > 0
                                      ? 'Disponible · ${p.stock} en stock'
                                      : 'Temporalmente agotado',
                                  positive: p.stock > 0,
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'Todos los detalles para elegir con confianza.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: () => context.go('/'),
                                  icon: const Icon(
                                    Icons.grid_view_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Seguir explorando'),
                                ),
                              ],
                            );
                            final gallery = ProductGallery(
                              key: ValueKey(p.id),
                              product: p,
                            );
                            return c.maxWidth < 800
                                ? Column(
                                    children: [
                                      gallery,
                                      const SizedBox(height: 28),
                                      info,
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 6, child: gallery),
                                      const SizedBox(width: 48),
                                      Expanded(flex: 5, child: info),
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 36),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conócelo en detalle',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  p.description.isEmpty
                                      ? 'Consulta las características de este modelo a continuación.'
                                      : p.description,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    height: 1.7,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                LayoutBuilder(
                                  builder: (context, c) => Wrap(
                                    spacing: 20,
                                    runSpacing: 14,
                                    children: [
                                      spec(
                                        c.maxWidth,
                                        Icons.memory_outlined,
                                        'Memoria RAM',
                                        '${p.ram} GB',
                                      ),
                                      spec(
                                        c.maxWidth,
                                        Icons.storage_rounded,
                                        'Almacenamiento',
                                        '${p.storage} GB',
                                      ),
                                      spec(
                                        c.maxWidth,
                                        Icons.smartphone_outlined,
                                        'Pantalla',
                                        '${p.screen} pulgadas',
                                      ),
                                      spec(
                                        c.maxWidth,
                                        Icons.battery_charging_full_rounded,
                                        'Batería',
                                        '${p.battery} mAh',
                                      ),
                                      spec(
                                        c.maxWidth,
                                        Icons.settings_outlined,
                                        'Sistema operativo',
                                        p.os,
                                      ),
                                      spec(
                                        c.maxWidth,
                                        Icons.palette_outlined,
                                        'Color',
                                        p.color,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
  Widget spec(double width, IconData icon, String label, String value) =>
      SizedBox(
        width: width < 600 ? width : (width - 40) / 3,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 23, color: AppColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
