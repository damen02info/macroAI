import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/meal_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
                          (meal) => MealCard(meal: meal),
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
