import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class CatalogHero extends StatelessWidget {
  const CatalogHero({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 650;
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFE9EFFC), Color(0xFFF1F4FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(compact ? 24 : 42),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TU SIGUIENTE CONEXIÓN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Tu próximo celular\nestá aquí.',
                    style: TextStyle(
                      fontSize: compact ? 31 : 49,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1.5,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Compara modelos, descubre los detalles\ny encuentra el que va contigo.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.muted,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 17,
                          color: AppColors.blue,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Todo el catálogo, en un solo lugar.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (constraints.maxWidth > 400 &&
                MediaQuery.textScalerOf(context).scale(14) < 22)
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: compact ? 210 : 250,
                  child: const PhoneArt(),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class PhoneArt extends StatelessWidget {
  const PhoneArt({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Transform.rotate(
      angle: .12,
      child: AspectRatio(
        aspectRatio: .51,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF14203B),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: .18),
                blurRadius: 28,
                offset: const Offset(4, 15),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1C3B84),
                  Color(0xFF4779E0),
                  Color(0xFFBACDF8),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 7,
                  child: Container(
                    width: 42,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14203B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFDAE6FF),
                    size: 62,
                  ),
                ),
                Positioned(
                  bottom: 9,
                  child: Container(
                    width: 38,
                    height: 3,
                    color: const Color(0xFFDAE6FF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
