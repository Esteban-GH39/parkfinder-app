import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/billetera_service.dart';
import '../../services/perfil_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import '../../utils/formato.dart';
import '../cliente/billetera_screen.dart';
import '../cliente/login_screen.dart';

/// Perfil de la cuenta, el mismo para cliente y administrador (dueño de parqueadero).
/// Permite ver los datos, cambiar el nombre (y el teléfono si es administrador), cambiar la contraseña
/// y cerrar sesión. El cliente además llega desde aquí a su billetera.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({
    super.key,
    PerfilService? servicio,
    BilleteraService? billeteraService,
  }) : _servicio = servicio,
       _billeteraService = billeteraService;

  final PerfilService? _servicio;
  final BilleteraService? _billeteraService;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

final _formatoContrasena = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

class _PerfilScreenState extends State<PerfilScreen> {
  final _sesion = SesionService.instancia;
  late final PerfilService _servicio = widget._servicio ?? PerfilService();
  late final BilleteraService _billetera =
      widget._billeteraService ?? BilleteraService();

  final _datosKey = GlobalKey<FormState>();
  final _claveKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  Map<String, dynamic>? _perfil;
  int? _saldo;
  bool _cargando = true;
  bool _guardando = false;
  bool _cambiandoClave = false;
  String? _errorCarga;
  String? _errorDatos;
  String? _exitoDatos;
  String? _errorClave;
  String? _exitoClave;

  bool get _esAdmin => _sesion.esAdmin;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = _sesion.id;
    if (id == null) {
      setState(() {
        _cargando = false;
        _errorCarga = 'Vuelve a iniciar sesión para ver tu perfil.';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    final r = await _servicio.obtener(id);
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() {
        _cargando = false;
        _errorCarga = '${r['error']}';
      });
      return;
    }
    final perfil = r['data'] as Map<String, dynamic>;
    setState(() {
      _perfil = perfil;
      _nombreCtrl.text = '${perfil['nombre'] ?? ''}';
      _telefonoCtrl.text = '${perfil['telefono'] ?? ''}';
      _cargando = false;
    });
    if (!_esAdmin) {
      final saldo = await _billetera.saldo(id);
      if (mounted) setState(() => _saldo = saldo);
    }
  }

  Future<void> _guardar() async {
    final id = _sesion.id;
    if (id == null || !_datosKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _errorDatos = null;
      _exitoDatos = null;
    });
    final telefono = int.tryParse(_telefonoCtrl.text.trim());
    final r = await _servicio.actualizar(
      id,
      nombre: _nombreCtrl.text.trim(),
      telefono: _esAdmin ? telefono : null,
    );
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() {
        _guardando = false;
        _errorDatos = '${r['error']}';
      });
      return;
    }
    final perfil = r['data'] as Map<String, dynamic>;
    _sesion.actualizarNombre('${perfil['nombre']}');
    setState(() {
      _guardando = false;
      _perfil = perfil;
      _exitoDatos = 'Cambios guardados';
    });
  }

  Future<void> _cambiarContrasena() async {
    final id = _sesion.id;
    if (id == null || !_claveKey.currentState!.validate()) return;
    setState(() {
      _cambiandoClave = true;
      _errorClave = null;
      _exitoClave = null;
    });
    final r = await _servicio.cambiarContrasena(
      id,
      actual: _actualCtrl.text,
      nueva: _nuevaCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _cambiandoClave = false;
      if (r['success'] == true) {
        _exitoClave = 'Contraseña actualizada';
        _actualCtrl.clear();
        _nuevaCtrl.clear();
        _confirmarCtrl.clear();
        _claveKey.currentState?.reset();
      } else {
        _errorClave = '${r['error']}';
      }
    });
  }

  Future<void> _verBilletera() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BilleteraScreen()),
    );
    final id = _sesion.id;
    if (id == null) return;
    final saldo = await _billetera.saldo(id);
    if (mounted) setState(() => _saldo = saldo);
  }

  void _salir() {
    _sesion.cerrar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _errorCarga != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AvisoError(texto: _errorCarga!),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            : _contenido(),
      ),
    );
  }

  Widget _contenido() {
    final perfil = _perfil!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        TarjetaBlanca(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.oscuro,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${perfil['nombre'] ?? '?'}'.trim().isEmpty
                      ? '?'
                      : '${perfil['nombre']}'.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${perfil['nombre'] ?? ''}',
                      key: const Key('perfilNombre'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${perfil['correo'] ?? ''}',
                      key: const Key('perfilCorreo'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textoSuave,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    EtiquetaRol(admin: _esAdmin),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!_esAdmin) ...[
          const SizedBox(height: 12),
          Material(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              key: const Key('botonVerBilletera'),
              borderRadius: BorderRadius.circular(24),
              onTap: _verBilletera,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Mi billetera',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _saldo == null ? '' : pesos(_saldo!),
                      key: const Key('perfilSaldo'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textoSuave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _datos(perfil),
        const SizedBox(height: 12),
        _contrasena(),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('botonCerrarSesion'),
          onPressed: _salir,
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }

  Widget _datos(Map<String, dynamic> perfil) {
    return TarjetaBlanca(
      child: Form(
        key: _datosKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis datos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('campoNombrePerfil'),
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'El nombre es requerido';
                if (t.length > 100) return 'Máximo 100 caracteres';
                return null;
              },
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            if (_esAdmin) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campoTelefonoPerfil'),
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null; // se conserva el que ya tenía
                  return RegExp(r'^3\d{9}$').hasMatch(t)
                      ? null
                      : 'Debe tener 10 dígitos y empezar por 3';
                },
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              if (perfil['cedula'] != null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('campoCedulaPerfil'),
                  initialValue: '${perfil['cedula']}',
                  readOnly: true,
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Cédula'),
                ),
              ],
            ],
            const SizedBox(height: 8),
            const Text(
              'El correo no se puede cambiar.',
              style: TextStyle(color: AppColors.textoSuave, fontSize: 12),
            ),
            if (_errorDatos != null) ...[
              const SizedBox(height: 12),
              AvisoError(texto: _errorDatos!),
            ],
            if (_exitoDatos != null) ...[
              const SizedBox(height: 12),
              Text(
                _exitoDatos!,
                key: const Key('avisoPerfilGuardado'),
                style: const TextStyle(
                  color: AppColors.exito,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('botonGuardarPerfil'),
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const CargandoEnBoton()
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contrasena() {
    return TarjetaBlanca(
      child: Form(
        key: _claveKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cambiar contraseña',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('campoClaveActual'),
              controller: _actualCtrl,
              obscureText: true,
              validator: (v) =>
                  (v ?? '').isEmpty ? 'Escribe tu contraseña actual' : null,
              decoration: const InputDecoration(labelText: 'Contraseña actual'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('campoClaveNueva'),
              controller: _nuevaCtrl,
              obscureText: true,
              validator: (v) => _formatoContrasena.hasMatch(v ?? '')
                  ? null
                  : 'Mínimo 8 caracteres, con una letra y un número',
              decoration: const InputDecoration(labelText: 'Contraseña nueva'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('campoClaveConfirmar'),
              controller: _confirmarCtrl,
              obscureText: true,
              validator: (v) =>
                  v == _nuevaCtrl.text ? null : 'Las contraseñas no coinciden',
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña nueva',
              ),
            ),
            if (_errorClave != null) ...[
              const SizedBox(height: 12),
              AvisoError(texto: _errorClave!),
            ],
            if (_exitoClave != null) ...[
              const SizedBox(height: 12),
              Text(
                _exitoClave!,
                key: const Key('avisoClaveCambiada'),
                style: const TextStyle(
                  color: AppColors.exito,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('botonCambiarClave'),
              onPressed: _cambiandoClave ? null : _cambiarContrasena,
              child: _cambiandoClave
                  ? const CargandoEnBoton()
                  : const Text('Cambiar contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
