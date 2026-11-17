import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/store_widgets.dart';
import '../../catalog/data/store_repository.dart';
import '../../catalog/domain/product.dart';

Future<Brand?> editBrand(
  BuildContext context,
  StoreRepository repository, {
  Brand? brand,
}) => showDialog<Brand>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _BrandDialog(repository: repository, brand: brand),
);

class _BrandDialog extends StatefulWidget {
  const _BrandDialog({required this.repository, this.brand});
  final StoreRepository repository;
  final Brand? brand;
  @override
  State<_BrandDialog> createState() => _BrandDialogState();
}

class _BrandDialogState extends State<_BrandDialog> {
  late final name = TextEditingController(text: widget.brand?.name ?? '');
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.repository.saveBrand(
        name.text.trim(),
        id: widget.brand?.id,
      );
      if (mounted) Navigator.pop(context, result);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(widget.brand == null ? 'Nueva marca' : 'Editar marca'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ErrorNotice(error!),
              TextFormField(
                controller: name,
                enabled: !busy,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la marca',
                ),
                onFieldSubmitted: (_) => busy ? null : save(),
                validator: (s) =>
                    s == null || s.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Guardando…' : 'Guardar'),
        ),
      ],
    ),
  );
}
