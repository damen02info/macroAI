import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final tdeeCtrl = TextEditingController();
  final proCtrl = TextEditingController();
  final carbCtrl = TextEditingController();
  final fatCtrl = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<DashboardProvider>();
    tdeeCtrl.text = p.targetKcal.toInt().toString();
    proCtrl.text = p.proteinTarget.toInt().toString();
    carbCtrl.text = p.carbTarget.toInt().toString();
    fatCtrl.text = p.fatTarget.toInt().toString();
  }

  @override
  void dispose() {
    tdeeCtrl.dispose();
    proCtrl.dispose();
    carbCtrl.dispose();
    fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => isSaving = true);
    try {
      await context.read<DashboardProvider>().saveProfile(
        double.tryParse(tdeeCtrl.text) ?? 0,
        double.tryParse(proCtrl.text) ?? 0,
        double.tryParse(carbCtrl.text) ?? 0,
        double.tryParse(fatCtrl.text) ?? 0,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metas Nutricionales')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: tdeeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'TDEE (kcal)')),
          TextField(controller: proCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Proteínas (g)')),
          TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbos (g)')),
          TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Grasas (g)')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isSaving ? null : _handleSave,
            child: isSaving ? const CircularProgressIndicator() : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}