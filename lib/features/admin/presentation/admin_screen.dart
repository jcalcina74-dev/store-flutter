import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/catalog_events.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/store_widgets.dart';
import '../../auth/application/admin_session.dart';
import '../../catalog/application/catalog_controller.dart';
import '../../catalog/data/store_repository.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/widgets/catalog_toolbar.dart';
import '../../catalog/presentation/widgets/catalog_pagination.dart';
import 'brand_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final CatalogController controller;
  final search = TextEditingController();
  final deleting = <int>{};
  int tab = 0;
  @override
  void initState() {
    super.initState();
    controller = CatalogController(
      context.read<StoreRepository>(),
      context.read<CatalogEvents>(),
      admin: true,
    );
    unawaited(controller.refresh());
  }

  @override
  void dispose() {
    controller.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> brand([Brand? value]) async {
    final result = await editBrand(
      context,
      context.read<StoreRepository>(),
      brand: value,
    );
    if (result != null) unawaited(controller.refresh());
  }

  Future<void> deleteBrand(Brand value) async {
    if (!await confirmAction(
      context,
      title: 'Eliminar marca',
      message:
          '¿Eliminar la marca ${value.name}? Solo es posible si no tiene celulares.',
    )) {
      return;
    }
    try {
      await controller.repository.deleteBrand(value.id);
      unawaited(controller.refresh());
      if (mounted) showMessage(context, 'Marca eliminada.');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> deleteProduct(Product value) async {
    if (!await confirmAction(
      context,
      title: 'Eliminar celular',
      message:
          '¿Eliminar ${value.displayName} y todas sus imágenes? Esta acción no se puede deshacer.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => deleting.add(value.id));
    try {
      await controller.repository.deleteProduct(value.id);
      unawaited(controller.refresh());
      if (mounted) showMessage(context, 'Celular eliminado.');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => deleting.remove(value.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => tab == 0 ? context.push('/admin/nuevo') : brand(),
      icon: const Icon(Icons.add_rounded),
      label: Text(tab == 0 ? 'Nuevo celular' : 'Nueva marca'),
    ),
    body: Column(
      children: [
        StoreHeader(
          back: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LiveBadge(),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  context.go('/');
                  context.read<AdminSession>().signOut();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: PageWidth(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ADMINISTRACIÓN',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              color: Color(0xFFA9C0F5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tu catálogo, al día.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${controller.total} celulares  ·  ${controller.brands.length} marcas',
                            style: const TextStyle(color: Color(0xFFB7C4DC)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('Celulares'),
                          icon: Icon(Icons.smartphone_outlined),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Marcas'),
                          icon: Icon(Icons.sell_outlined),
                        ),
                      ],
                      selected: {tab},
                      onSelectionChanged: (s) => setState(() => tab = s.first),
                    ),
                    const SizedBox(height: 22),
                    if (controller.error != null)
                      ErrorNotice(controller.error!, retry: controller.refresh),
                    if (controller.refreshing)
                      const LinearProgressIndicator(minHeight: 2),
                    if (controller.loading)
                      const Padding(
                        padding: EdgeInsets.all(60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (tab == 0) ...[
                      CatalogToolbar(controller: controller, search: search),
                      const SizedBox(height: 20),
                      if (controller.products.isEmpty)
                        EmptyState(
                          title: 'Tu catálogo empieza aquí',
                          message:
                              'Añade un celular y publícalo cuando esté listo.',
                          icon: Icons.add_box_outlined,
                          action: () => context.push('/admin/nuevo'),
                          label: 'Crear celular',
                        ),
                      for (final product in controller.products)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _productRow(product),
                        ),
                      const SizedBox(height: 12),
                      CatalogPagination(controller: controller),
                    ] else ...[
                      if (controller.brands.isEmpty)
                        EmptyState(
                          title: 'Organiza tus marcas',
                          message: 'Crea una marca antes de añadir tu primer celular.',
                          icon: Icons.sell_outlined,
                          action: brand,
                          label: 'Nueva marca',
                        ),
                      for (final value in controller.brands)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              leading: const CircleAvatar(
                                child: Icon(Icons.sell_outlined, size: 20),
                              ),
                              title: Text(
                                value.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Opciones de marca',
                                onSelected: (action) => action == 'edit'
                                    ? brand(value)
                                    : deleteBrand(value),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _productRow(Product p) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 78,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ProductPhoto(product: p, admin: true),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  p.brand.name.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 9,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      p.formattedPrice,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    StatusPill(
                      p.active ? 'Publicado' : 'Borrador',
                      positive: p.active,
                    ),
                    Text(
                      'Stock: ${p.stock}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (deleting.contains(p.id))
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Opciones de celular',
              onSelected: (action) {
                if (action == 'edit') {
                  context.push('/admin/producto/${p.id}');
                } else {
                  unawaited(deleteProduct(p));
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
        ],
      ),
    ),
  );
}
