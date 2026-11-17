import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/store_widgets.dart';
import '../../catalog/data/store_repository.dart';
import '../application/admin_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final user = TextEditingController(), password = TextEditingController();
  bool visible = false;
  @override
  void dispose() {
    user.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    final session = context.read<AdminSession>();
    final success = await session.signIn(
      context.read<StoreRepository>(),
      user.text,
      password.text,
    );
    if (mounted && success) context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSession>();
    return Scaffold(
      body: Column(
        children: [
          const StoreHeader(back: true),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: form,
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF0FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: AppColors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Todo bajo control.',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 9),
                              const Text(
                                'Ingresa para administrar tu catálogo.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                              const SizedBox(height: 26),
                              if (session.error != null)
                                ErrorNotice(session.error!),
                              TextFormField(
                                key: const Key('admin-user'),
                                controller: user,
                                enabled: !session.busy,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'Usuario',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (s) => s == null || s.trim().isEmpty
                                    ? 'Ingresa tu usuario'
                                    : s.contains(':')
                                    ? 'Usuario no válido'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('admin-password'),
                                controller: password,
                                enabled: !session.busy,
                                obscureText: !visible,
                                autofillHints: const [AutofillHints.password],
                                enableSuggestions: false,
                                autocorrect: false,
                                onFieldSubmitted: (_) => submit(),
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: visible
                                        ? 'Ocultar contraseña'
                                        : 'Mostrar contraseña',
                                    onPressed: () =>
                                        setState(() => visible = !visible),
                                    icon: Icon(
                                      visible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (s) => s == null || s.isEmpty
                                    ? 'Ingresa tu contraseña'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: session.busy ? null : submit,
                                  child: session.busy
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Ingresar al panel'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () => context.go('/'),
                                  child: const Text('Volver al catálogo'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
