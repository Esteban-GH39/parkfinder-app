import 'package:flutter/material.dart';

import 'usuario_api.dart';

/// HU-01: pantalla de registro de cuenta de cliente.
///
/// Las validaciones locales replican los criterios de aceptación de la HU para
/// dar feedback inmediato; el backend vuelve a validarlas de todos modos.
class RegistroClienteScreen extends StatefulWidget {
  const RegistroClienteScreen({super.key, this.api});

  /// Permite inyectar un [UsuarioApi] falso en pruebas.
  final UsuarioApi? api;

  @override
  State<RegistroClienteScreen> createState() => _RegistroClienteScreenState();
}

class _RegistroClienteScreenState extends State<RegistroClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final UsuarioApi _api = widget.api ?? UsuarioApi();

  bool _passwordVisible = false;
  bool _enviando = false;
  String? _errorEmail;

  static final _formatoEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  bool get _largoOk => _passwordCtrl.text.length >= 8;

  bool get _mezclaOk =>
      RegExp(r'[A-Za-z]').hasMatch(_passwordCtrl.text) &&
      RegExp(r'\d').hasMatch(_passwordCtrl.text);

  @override
  void initState() {
    super.initState();
    // Repinta la lista de requisitos de contraseña mientras el usuario escribe.
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    if (widget.api == null) {
      _api.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    setState(() => _errorEmail = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _enviando = true);
    try {
      final usuario = await _api.registrarCliente(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cuenta creada para ${usuario.email}')),
      );
    } on EmailYaRegistradoException {
      if (!mounted) return;
      // El 409 se muestra pegado al campo de correo, que es el que lo causa.
      setState(() => _errorEmail = 'Ya existe una cuenta registrada con este correo');
      _formKey.currentState!.validate();
    } on ValidacionException catch (e) {
      if (!mounted) return;
      _mostrarError(e.mensaje);
    } catch (_) {
      if (!mounted) return;
      _mostrarError('No fue posible conectar con el servidor. Revisa tu conexión.');
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_parking_rounded,
                        color: theme.colorScheme.primary, size: 26),
                    const SizedBox(width: 8),
                    Text('ParkFinder',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Crear cuenta',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Reserva tu puesto de parqueadero en segundos.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ana Pérez',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'ana@correo.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_errorEmail != null) return _errorEmail;
                    if (v == null || v.trim().isEmpty) {
                      return 'El correo es obligatorio';
                    }
                    if (!_formatoEmail.hasMatch(v.trim())) {
                      return 'El correo no tiene un formato válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Mínimo 8 caracteres',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      tooltip: _passwordVisible
                          ? 'Ocultar contraseña'
                          : 'Mostrar contraseña',
                    ),
                  ),
                  validator: (v) {
                    if (!_largoOk || !_mezclaOk) {
                      return 'La contraseña debe tener mínimo 8 caracteres, '
                          'con al menos una letra y un número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _RequisitoPassword(
                    texto: 'Mínimo 8 caracteres', cumplido: _largoOk),
                const SizedBox(height: 6),
                _RequisitoPassword(
                    texto: 'Al menos una letra y un número',
                    cumplido: _mezclaOk),

                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _enviando ? null : _registrar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Crear cuenta'),
                ),
                const SizedBox(height: 20),

                const Center(
                  child: TextButton(
                    // HU-02 (login) todavía no implementada.
                    onPressed: null,
                    child: Text('¿Ya tienes cuenta? Inicia sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de requisito de contraseña, que se marca en verde al cumplirse.
class _RequisitoPassword extends StatelessWidget {
  const _RequisitoPassword({required this.texto, required this.cumplido});

  final String texto;
  final bool cumplido;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = cumplido
        ? Colors.green.shade700
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(
          cumplido ? Icons.check_rounded : Icons.circle,
          size: cumplido ? 16 : 6,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
    );
  }
}
