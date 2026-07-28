import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/meal_model.dart';
import 'widgets/meal_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _showEditDialog(BuildContext context, MealModel meal) {
    showDialog(
      context: context,
      builder: (context) => EditMealDialog(meal: meal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final grouped = provider.groupedHistoryMeals;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'day', label: Text('Diario')),
                ButtonSegment(value: 'week', label: Text('Semanal')),
                ButtonSegment(value: 'month', label: Text('Mensual')),
              ],
              selected: {provider.currentPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                provider.changeHistoryPeriod(newSelection.first);
              },
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.historyMeals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.historyMeals.isEmpty
                ? const Center(child: Text('No hay registros en este periodo.'))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: grouped.entries.expand((entry) {
                      final summary = entry.value;
                      return [
                        if (provider.currentPeriod != 'day')
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summary.dateKey,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Objetivo: ${summary.targetKcal.toInt()} Kcal (${summary.targetProtein.toInt()}g Pro, ${summary.targetCarb.toInt()}g Car, ${summary.targetFat.toInt()}g Gra)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Consumido: ${summary.consumedKcal.toInt()} Kcal (${summary.consumedProtein.toInt()}g Pro, ${summary.consumedCarb.toInt()}g Car, ${summary.consumedFat.toInt()}g Gra)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ...summary.meals.map(
                          (meal) => Stack(
                            children: [
                              MealCard(meal: meal),
                              if (provider.currentPeriod == 'day')
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueGrey,
                                    ),
                                    onPressed: () =>
                                        _showEditDialog(context, meal),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ];
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- PANTALLA FLOTANTE DE EDICIÓN ---
class EditMealDialog extends StatefulWidget {
  final MealModel meal;

  const EditMealDialog({super.key, required this.meal});

  @override
  State<EditMealDialog> createState() => _EditMealDialogState();
}

class _EditMealDialogState extends State<EditMealDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _kcalCtrl;
  late TextEditingController _proCtrl;
  late TextEditingController _carbCtrl;
  late TextEditingController _fatCtrl;
  final TextEditingController _promptCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.meal.nombrePlato.toString());
    _kcalCtrl = TextEditingController(text: widget.meal.calorias.toString());
    _proCtrl = TextEditingController(text: widget.meal.proteinas.toString());
    _carbCtrl = TextEditingController(
      text: widget.meal.carbohidratos.toString(),
    );
    _fatCtrl = TextEditingController(text: widget.meal.grasas.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return AlertDialog(
      title: const Text('Editar o Refinar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edición Manual',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la comida',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kcalCtrl,
                    decoration: const InputDecoration(labelText: 'Kcal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _proCtrl,
                    decoration: const InputDecoration(labelText: 'Pro (g)'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carbCtrl,
                    decoration: const InputDecoration(labelText: 'Car (g)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatCtrl,
                    decoration: const InputDecoration(labelText: 'Gra (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await provider.updateMealManual(
                    widget.meal.id,
                    _nameCtrl.text,
                    double.tryParse(_kcalCtrl.text) ?? 0,
                    double.tryParse(_proCtrl.text) ?? 0,
                    double.tryParse(_carbCtrl.text) ?? 0,
                    double.tryParse(_fatCtrl.text) ?? 0,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar Manualmente'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            const Text(
              'Refinar con IA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ej: Añade 20g de aceite a lo anterior',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Re-analizar'),
                onPressed: () async {
                  if (_promptCtrl.text.isEmpty) return;
                  await provider.refineMealWithPrompt(
                    widget.meal.id,
                    _promptCtrl.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
