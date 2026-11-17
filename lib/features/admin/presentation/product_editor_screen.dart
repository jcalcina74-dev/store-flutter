import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/store_widgets.dart';
import '../../catalog/data/store_repository.dart';
import '../../catalog/domain/product.dart';
import '../application/product_editor_controller.dart';
import 'brand_dialog.dart';

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({this.id, super.key});
  final int? id;
  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  late final ProductEditorController controller;
  final form = GlobalKey<FormState>();
  final picker = ImagePicker();
  final inputs = <String, TextEditingController>{
    for (final key in [
      'modelo',
      'descripcion',
      'precio',
      'stock',
      'ramGb',
      'almacenamientoGb',
      'pantallaPulgadas',
      'bateriaMah',
      'sistemaOperativo',
      'color',
    ])
      key: TextEditingController(),
  };
  int? brandId;
  bool active = true, dirty = false;
  XFile? recovered;
  String? imageError;

  @override
  void initState() {
    super.initState();
    controller = ProductEditorController(
      context.read<StoreRepository>(),
      widget.id,
    );
    unawaited(load());
  }

  Future<void> load() async {
    await controller.load();
    if (!mounted) return;
    final p = controller.product;
    final defaults = <String, String>{
      'modelo': p?.model ?? '',
      'descripcion': p?.description ?? '',
      'precio': p?.price.toStringAsFixed(2) ?? '',
      'stock': p?.stock.toString() ?? '1',
      'ramGb': p?.ram.toString() ?? '8',
      'almacenamientoGb': p?.storage.toString() ?? '128',
      'pantallaPulgadas': p?.screen.toString() ?? '6.5',
      'bateriaMah': p?.battery.toString() ?? '5000',
      'sistemaOperativo': p?.os ?? 'Android',
      'color': p?.color ?? 'Negro',
    };
    defaults.forEach((key, value) => inputs[key]!.text = value);
    setState(() {
      brandId =
          p?.brand.id ??
          (controller.brands.isEmpty ? null : controller.brands.first.id);
      active = p?.active ?? true;
      dirty = false;
    });
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        widget.id != null) {
      try {
        final response = await picker.retrieveLostData();
        if (mounted && response.files?.isNotEmpty == true) {
          setState(() => recovered = response.files!.first);
        }
      } catch (_) {
        // Recuperación opcional del selector Android; no impide editar el producto.
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    for (final input in inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  Future<void> leave() async {
    if (controller.busy) return;
    if (dirty &&
        !await confirmAction(
          context,
          title: '¿Salir sin guardar?',
          message: 'Los cambios del formulario todavía no se guardaron.',
          confirm: 'Salir',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.canPop() ? context.pop() : context.go('/admin');
    });
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final isNew = controller.id == null;
    final data = <String, dynamic>{
      'marcaId': brandId,
      'modelo': inputs['modelo']!.text.trim(),
      'descripcion': inputs['descripcion']!.text.trim(),
      'precio': double.parse(inputs['precio']!.text.replaceAll(',', '.')),
      'stock': int.parse(inputs['stock']!.text),
      'ramGb': int.parse(inputs['ramGb']!.text),
      'almacenamientoGb': int.parse(inputs['almacenamientoGb']!.text),
      'pantallaPulgadas': double.parse(
        inputs['pantallaPulgadas']!.text.replaceAll(',', '.'),
      ),
      'bateriaMah': int.parse(inputs['bateriaMah']!.text),
      'sistemaOperativo': inputs['sistemaOperativo']!.text.trim(),
      'color': inputs['color']!.text.trim(),
      'activo': active,
    };
    final result = await controller.save(data);
    if (!mounted || result == null) return;
    setState(() => dirty = false);
    showMessage(
      context,
      isNew
          ? 'Celular creado. Ya puedes añadir sus imágenes.'
          : 'Cambios guardados.',
    );
    if (isNew) context.go('/admin/producto/${result.id}');
  }

  Future<void> addBrand() async {
    final result = await editBrand(context, controller.repository);
    if (!mounted || result == null) return;
    controller.brands = [...controller.brands, result];
    setState(() {
      brandId = result.id;
      dirty = true;
    });
  }

  Future<void> upload([XFile? candidate]) async {
    if (controller.busy) return;
    setState(() => imageError = null);
    try {
      final file =
          candidate ??
          await picker.pickImage(
            source: ImageSource.gallery,
            requestFullMetadata: false,
          );
      if (file == null || !mounted) return;
      if (await file.length() > 5 * 1024 * 1024) {
        if (mounted) {
          setState(() => imageError = 'La imagen no puede superar los 5 MB.');
        }
        return;
      }
      final success = await controller.upload(
        await file.readAsBytes(),
        file.name,
      );
      if (mounted && success) {
        setState(() => recovered = null);
        showMessage(context, 'Imagen añadida.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => imageError = 'No se pudo abrir la imagen. Selecciona un archivo JPEG, PNG o WebP.',
        );
      }
    }
  }

  Future<void> removeImage(ProductImage image) async {
    if (!await confirmAction(
      context,
      title: 'Eliminar imagen',
      message: 'Esta imagen se quitará del catálogo.',
    )) {
      return;
    }
    final success = await controller.deleteImage(image.id);
    if (mounted && success) showMessage(context, 'Imagen eliminada.');
  }

  Widget field(
    String key,
    String label, {
    int maxLength = 120,
    bool decimal = false,
    num? maximum,
    bool zero = false,
  }) {
    final numeric = decimal || maximum != null;
    return TextFormField(
      key: ValueKey('field-$key'),
      controller: inputs[key],
      enabled: !controller.busy,
      textInputAction: TextInputAction.next,
      keyboardType: numeric
          ? TextInputType.numberWithOptions(decimal: decimal)
          : TextInputType.text,
      maxLength: numeric ? null : maxLength,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (value) {
        final s = (value ?? '').trim();
        if (s.isEmpty) return 'Este campo es obligatorio';
        if (!numeric) {
          return s.length > maxLength ? 'Máximo $maxLength caracteres' : null;
        }
        final valid = decimal
            ? RegExp(r'^\d+([.,]\d{1,2})?$')
            : RegExp(r'^\d+$');
        final number = double.tryParse(s.replaceAll(',', '.'));
        if (!valid.hasMatch(s) || number == null || !number.isFinite) {
          return decimal ? 'Usa hasta 2 decimales' : 'Ingresa un número entero';
        }
        if (number <
            (zero
                ? 0
                : decimal
                ? .01
                : 1)) {
          return zero ? 'No puede ser negativo' : 'Debe ser mayor que cero';
        }
        if (number > (maximum ?? 9999999999.99)) {
          return 'Supera el máximo permitido';
        }
        return null;
      },
    );
  }

  Widget section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    ),
  );

  Widget fields(List<Widget> children) => LayoutBuilder(
    builder: (context, c) {
      final width = c.maxWidth < 640 ? c.maxWidth : (c.maxWidth - 16) / 2;
      return Wrap(
        spacing: 16,
        runSpacing: 18,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => PopScope(
      canPop: !dirty && !controller.busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(leave());
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            tooltip: 'Volver al panel',
            onPressed: controller.busy ? null : leave,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            widget.id == null ? 'Nuevo celular' : 'Editar celular',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        bottomNavigationBar: controller.loading
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: PageWidth(
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: controller.busy ? null : leave,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: controller.busy ? null : save,
                            icon: controller.saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              controller.saving
                                  ? 'Guardando…'
                                  : 'Guardar celular',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        body: controller.loading
            ? const Center(child: CircularProgressIndicator())
            : controller.error != null &&
                  (widget.id != null && controller.product == null ||
                      controller.brands.isEmpty)
            ? EmptyState(
                title: 'No pudimos abrir el formulario',
                message: controller.error!,
                action: load,
              )
            : SingleChildScrollView(
                child: PageWidth(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Form(
                      key: form,
                      onChanged: () {
                        if (!dirty) setState(() => dirty = true);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (controller.error != null)
                            ErrorNotice(controller.error!),
                          section('Información del celular', [
                            fields([
                              DropdownButtonFormField<int>(
                                key: ValueKey(brandId),
                                initialValue: brandId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Marca',
                                ),
                                items: [
                                  for (final brand in controller.brands)
                                    DropdownMenuItem(
                                      value: brand.id,
                                      child: Text(brand.name.toUpperCase()),
                                    ),
                                ],
                                onChanged: controller.busy
                                    ? null
                                    : (v) => setState(() {
                                        brandId = v;
                                        dirty = true;
                                      }),
                                validator: (v) => v == null
                                    ? 'Crea y selecciona una marca'
                                    : null,
                              ),
                              field('modelo', 'Modelo'),
                            ]),
                            TextButton.icon(
                              onPressed: controller.busy ? null : addBrand,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Crear marca'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: inputs['descripcion'],
                              enabled: !controller.busy,
                              maxLines: 4,
                              maxLength: 5000,
                              decoration: const InputDecoration(
                                labelText: 'Descripción',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 18),
                          section('Precio y disponibilidad', [
                            fields([
                              field('precio', 'Precio en Bs', decimal: true),
                              field(
                                'stock',
                                'Unidades en stock',
                                maximum: 2147483647,
                                zero: true,
                              ),
                            ]),
                            const SizedBox(height: 18),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: active,
                              onChanged: controller.busy
                                  ? null
                                  : (v) => setState(() {
                                      active = v;
                                      dirty = true;
                                    }),
                              title: const Text('Publicar en el catálogo'),
                              subtitle: const Text(
                                'Si está desactivado, solo lo verá el administrador.',
                              ),
                            ),
                          ]),
                          const SizedBox(height: 18),
                          section('Especificaciones', [
                            fields([
                              field('ramGb', 'Memoria RAM (GB)', maximum: 256),
                              field(
                                'almacenamientoGb',
                                'Almacenamiento (GB)',
                                maximum: 16384,
                              ),
                              field(
                                'pantallaPulgadas',
                                'Pantalla (pulgadas)',
                                decimal: true,
                                maximum: 99.99,
                              ),
                              field(
                                'bateriaMah',
                                'Batería (mAh)',
                                maximum: 100000,
                              ),
                              field(
                                'sistemaOperativo',
                                'Sistema operativo',
                                maxLength: 80,
                              ),
                              field('color', 'Color', maxLength: 50),
                            ]),
                          ]),
                          const SizedBox(height: 18),
                          section('Imágenes', [
                            const Text(
                              'JPEG, PNG o WebP · Máximo 5 MB por imagen.\nLa primera imagen será la portada.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (imageError != null) ErrorNotice(imageError!),
                            if (controller.product == null)
                              const Text(
                                'Guarda el celular para añadir sus imágenes.',
                                style: TextStyle(color: AppColors.muted),
                              )
                            else ...[
                              Text(
                                '${controller.product!.images.length} de 8 imágenes',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final image
                                      in controller.product!.images)
                                    SizedBox(
                                      width: 126,
                                      height: 152,
                                      child: Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                child: ProductPhoto(
                                                  product: controller.product!,
                                                  image: image,
                                                  admin: true,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 1,
                                              top: 1,
                                              child: IconButton.filledTonal(
                                                tooltip: 'Eliminar imagen',
                                                onPressed: controller.busy
                                                    ? null
                                                    : () => removeImage(image),
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              if (controller.uploading)
                                const LinearProgressIndicator(),
                              OutlinedButton.icon(
                                onPressed:
                                    controller.busy ||
                                        controller.product!.images.length >= 8
                                    ? null
                                    : () => upload(),
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                                label: const Text('Añadir imagen'),
                              ),
                              if (recovered != null)
                                TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : () => upload(recovered),
                                  child: const Text('Añadir imagen recuperada'),
                                ),
                            ],
                          ]),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
}
