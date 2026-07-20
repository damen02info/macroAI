import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _tdeeCtrl = TextEditingController();
  final TextEditingController _proteinCtrl = TextEditingController();
  final TextEditingController _carbsCtrl = TextEditingController();
  final TextEditingController _fatsCtrl = TextEditingController();

  bool _isSyncing = false;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final api = context.read<ProgressProvider>().apiService;
      final currentEmail = api.getCurrentEmail();

      if (currentEmail != null && currentEmail.isNotEmpty) {
        _emailCtrl.text = currentEmail;

        try {
          await context.read<ProgressProvider>().fetchHistory();
          await _loadProfileData();
        } catch (e) {
          debugPrint('Error al cargar datos iniciales: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tdeeCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final api = context.read<ProgressProvider>().apiService;
      final profile = await api.getProfile();

      if (!mounted) return;

      if (profile != null) {
        setState(() {
          _tdeeCtrl.text = profile.tdeeObjetivo.toString();
          _proteinCtrl.text = profile.metaProteinas.toString();
          _carbsCtrl.text = profile.metaCarbos.toString();
          _fatsCtrl.text = profile.metaGrasas.toString();
        });
      }
    } catch (e) {
      debugPrint('Error al cargar perfil: $e');
    }
  }

  Future<void> _syncEmail() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un correo válido')),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final progressProvider = context.read<ProgressProvider>();

      await progressProvider.apiService.setSessionEmail(email);

      await progressProvider.fetchHistory();

      await _loadProfileData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos sincronizados correctamente')),
      );
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al conectar con el servidor')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final api = context.read<ProgressProvider>().apiService;

    final email = api.getCurrentEmail();

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes vincular un correo')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      await api.updateProfile(
        tdee: double.tryParse(_tdeeCtrl.text) ?? 0,
        proteinas: double.tryParse(_proteinCtrl.text) ?? 0,
        carbos: double.tryParse(_carbsCtrl.text) ?? 0,
        grasas: double.tryParse(_fatsCtrl.text) ?? 0,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil nutricional actualizado')),
      );
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el perfil')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuenta de usuario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSyncing ? null : _syncEmail,
                child: _isSyncing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Vincular y cargar datos'),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Si el correo no existe en la base de datos, se creará automáticamente un perfil nuevo.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 20),

            const Text(
              'Objetivos nutricionales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _tdeeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Calorías diarias (TDEE)',
                suffixText: 'kcal',
                border: OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'Proteínas',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller: _carbsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Carbohidratos',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller: _fatsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Grasas',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSavingProfile ? null : _saveProfile,
                child: _isSavingProfile
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar objetivos'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
