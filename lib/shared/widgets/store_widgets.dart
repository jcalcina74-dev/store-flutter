import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/realtime/catalog_events.dart';
import '../../features/auth/application/admin_session.dart';
import '../../features/catalog/data/store_repository.dart';
import '../../features/catalog/domain/product.dart';

class PageWidth extends StatelessWidget {
  const PageWidth({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
        ),
        child: child,
      ),
    ),
  );
}

class StoreHeader extends StatelessWidget {
  const StoreHeader({this.back = false, this.trailing, super.key});
  final bool back;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSession>();
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: PageWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                if (back) ...[
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                ],
                Semantics(
                  button: true,
                  label: 'NOVA, inicio',
                  child: InkWell(
                    key: const Key('store-logo'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go('/'),
                    onLongPress: () => context.push('/admin'),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.asset(
                              'assets/icons/app_icon.jpg',
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'NOVA STORE',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: 23,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (trailing != null)
                  trailing!
                else ...[
                  const LiveBadge(),
                  if (session.authenticated) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Administración',
                      onPressed: () => context.go('/admin'),
                      icon: const Icon(Icons.space_dashboard_outlined),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final status = context.watch<CatalogEvents>().status;
    final live = status == LiveStatus.live;
    final text = switch (status) {
      LiveStatus.live => 'Actualizado en vivo',
      LiveStatus.connecting => 'Conectando',
      LiveStatus.reconnecting => 'Reconectando',
      LiveStatus.paused => 'En pausa',
    };
    return Tooltip(
      message: text,
      child: Semantics(
        label: text,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: live ? const Color(0xFFECF7F2) : AppColors.background,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: live ? AppColors.green : AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 520) ...[
                const SizedBox(width: 7),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: live ? AppColors.green : AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    required this.product,
    this.image,
    this.admin = false,
    super.key,
  });
  final Product product;
  final ProductImage? image;
  final bool admin;
  @override
  Widget build(BuildContext context) {
    final photo =
        image ?? (product.images.isEmpty ? null : product.images.first);
    if (photo == null) return const PhonePlaceholder();
    final api = context.read<StoreRepository>().api;
    return Image.network(
      api.config.imageUrl(photo.url),
      headers: api.imageHeaders(admin: admin),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, error, stack) => const PhonePlaceholder(),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }
}

class PhonePlaceholder extends StatelessWidget {
  const PhonePlaceholder({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 100 || constraints.maxWidth < 80;
      return Center(
        child: Container(
          width: compact ? 40 : 86,
          height: compact ? 56 : 136,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDF5),
            borderRadius: BorderRadius.circular(compact ? 9 : 18),
            border: Border.all(color: const Color(0xFFD5DDEB), width: 2),
          ),
          child: compact
              ? const Icon(
                  Icons.smartphone_rounded,
                  size: 24,
                  color: Color(0xFF9DAAC2),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.smartphone_rounded,
                      size: 38,
                      color: Color(0xFF9DAAC2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sin imagen',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
        ),
      );
    },
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {this.positive = true, super.key});
  final String label;
  final bool positive;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: positive ? const Color(0xFFECF7F2) : const Color(0xFFF0F2F6),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: positive ? AppColors.green : AppColors.muted,
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.search_off_rounded,
    this.action,
    this.label = 'Reintentar',
    super.key,
  });
  final String title, message, label;
  final IconData icon;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(21),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.blue, size: 32),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            OutlinedButton(onPressed: action, child: Text(label)),
          ],
        ],
      ),
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.message, {this.retry, super.key});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer
          .withValues(alpha: .45),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
        if (retry != null)
          IconButton(
            onPressed: retry,
            tooltip: 'Reintentar',
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Eliminar',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;
void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
