import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/meal_model.dart';
import '../../../providers/dashboard_provider.dart';

class MealCard extends StatelessWidget {
  final MealModel meal;

  const MealCard({super.key, required this.meal});

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '$day/$month - $hour:$min';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(meal.nombrePlato, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${meal.calorias.toInt()} Kcal'),
            Text(
              _formatDate(meal.fechaHora),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroInfo('Pro', meal.proteinas, Colors.redAccent),
              _buildMacroInfo('Car', meal.carbohidratos, Colors.amber),
              _buildMacroInfo('Gra', meal.grasas, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meal.ingredientesEstimados,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                context.read<DashboardProvider>().deleteMeal(meal.id);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text('${value.toInt()}g'),
      ],
    );
  }
}