import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/progress_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  final TextEditingController _tdeeCtrl = TextEditingController();
  final TextEditingController _proteinCtrl = TextEditingController();
  final TextEditingController _carbsCtrl = TextEditingController();
  final TextEditingController _fatsCtrl = TextEditingController();

  bool _isWaitingForPin = false;
  bool _isLoadingAuth = false;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionAndLoad();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    _tdeeCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndLoad() async {
    final api = context.read<ProgressProvider>().apiService;
    if (api.hasSession) {
      _emailCtrl.text = api.getCurrentEmail() ?? '';
      await _loadProfileData();
    }
    setState(() {}); // Refresca UI tras comprobar la sesión
  }

  Future<void> _loadProfileData() async {
    try {
      final api = context.read<ProgressProvider>().apiService;
      final profile = await api.getProfile();
      if (profile != null) {
        setState(() {
          _tdeeCtrl.text = profile.tdeeObjetivo?.toString() ?? '';
          _proteinCtrl.text = profile.metaProteinas?.toString() ?? '';
          _carbsCtrl.text = profile.metaCarbos?.toString() ?? '';
          _fatsCtrl.text = profile.metaGrasas?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error al cargar perfil: $e');
    }
  }

  Future<void> _requestPin() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Correo inválido')));
      return;
    }

    setState(() => _isLoadingAuth = true);
    final api = context.read<ProgressProvider>().apiService;

    final success = await api.requestPin(email);

    setState(() {
      _isLoadingAuth = false;
      if (success) {
        _isWaitingForPin = true;
      }
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al enviar el PIN')));
    }
  }

  Future<void> _verifyPin() async {
    final email = _emailCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El PIN debe tener 6 dígitos')),
      );
      return;
    }

    setState(() => _isLoadingAuth = true);
    final api = context.read<ProgressProvider>().apiService;

    final success = await api.verifyPin(email, pin);

    if (success) {
      // Recargar datos globales de la app con el nuevo usuario
      if (mounted) {
        await context.read<DashboardProvider>().loadInitialData();
        await context.read<ProgressProvider>().fetchHistory();
        await _loadProfileData();
      }
      setState(() {
        _isWaitingForPin = false;
        _pinCtrl.clear();
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión iniciada correctamente')),
        );
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN incorrecto o caducado')),
        );
    }

    setState(() => _isLoadingAuth = false);
  }

  Future<void> _logout() async {
    final api = context.read<ProgressProvider>().apiService;
    await api.logout();

    // Limpiamos los providers
    if (mounted) {
      context.read<DashboardProvider>().historyMeals.clear();
      context.read<DashboardProvider>().todaysMeals.clear();
      context.read<ProgressProvider>().weightHistory.clear();
    }

    setState(() {
      _emailCtrl.clear();
      _tdeeCtrl.clear();
      _proteinCtrl.clear();
      _carbsCtrl.clear();
      _fatsCtrl.clear();
    });
  }

  Future<void> _saveProfile() async {
    final api = context.read<ProgressProvider>().apiService;
    if (!api.hasSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión primero')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      await api.updateProfile(
        tdee: double.tryParse(_tdeeCtrl.text) ?? 0.0,
        proteinas: double.tryParse(_proteinCtrl.text) ?? 0.0,
        carbos: double.tryParse(_carbsCtrl.text) ?? 0.0,
        grasas: double.tryParse(_fatsCtrl.text) ?? 0.0,
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil nutricional actualizado')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el perfil')),
        );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ProgressProvider>().apiService;
    final isLoggedIn = api.hasSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Cuenta de usuario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (isLoggedIn) ...[
              // VISTA: SESIÓN INICIADA
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
                title: Text(api.getCurrentEmail() ?? ''),
                subtitle: const Text('Sesión activa'),
                trailing: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Salir',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ] else ...[
              // VISTA: LOGIN / OTP
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isWaitingForPin,
                // Bloquear email si ya se pidió el PIN
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 10),

              if (_isWaitingForPin) ...[
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Código PIN (6 dígitos)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _isWaitingForPin = false;
                        _pinCtrl.clear();
                      }),
                      child: const Text('Cambiar correo'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isLoadingAuth ? null : _verifyPin,
                      child: _isLoadingAuth
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verificar PIN'),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _isLoadingAuth ? null : _requestPin,
                    child: _isLoadingAuth
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar PIN por correo'),
                  ),
                ),
              ],
            ],

            const Divider(height: 40, thickness: 1),

            const Text(
              '2. Objetivos Nutricionales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tdeeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: isLoggedIn,
              decoration: const InputDecoration(
                labelText: 'Calorías Diarias (TDEE)',
                border: OutlineInputBorder(),
                suffixText: 'kcal',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: isLoggedIn,
                    decoration: const InputDecoration(
                      labelText: 'Proteínas',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _carbsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: isLoggedIn,
                    decoration: const InputDecoration(
                      labelText: 'Carbos',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _fatsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: isLoggedIn,
                    decoration: const InputDecoration(
                      labelText: 'Grasas',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: FilledButton(
                onPressed: (!isLoggedIn || _isSavingProfile)
                    ? null
                    : _saveProfile,
                child: _isSavingProfile
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Guardar Objetivos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
