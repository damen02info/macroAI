import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    final double percent = (provider.targetKcal > 0)
        ? (provider.consumedKcal / provider.targetKcal).clamp(0.0, 1.0)
        : 0.0;
    final double remaining = provider.targetKcal - provider.consumedKcal;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CircularPercentIndicator(
      radius: 130.0,
      lineWidth: 18.0,
      percent: percent,
      animation: true,
      animateFromLastPercent: true,
      circularStrokeCap: CircularStrokeCap.round,
      center: provider.isLoading
          ? const CircularProgressIndicator() // <-- ESTADO DE CARGA
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            remaining > 0 ? '${remaining.toInt()}' : '0',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          Text(
            'Kcal restantes',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
      progressColor: Theme.of(context).primaryColor,
      backgroundColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
    );
  }
}