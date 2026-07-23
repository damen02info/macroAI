import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme.dart';

class MacroBars extends StatelessWidget {
  final double proteinGrams;
  final double proteinTarget;
  final double carbGrams;
  final double carbTarget;
  final double fatGrams;
  final double fatTarget;

  const MacroBars({
    super.key,
    required this.proteinGrams,
    required this.proteinTarget,
    required this.carbGrams,
    required this.carbTarget,
    required this.fatGrams,
    required this.fatTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMacroBar(
          context,
          label: 'Proteínas',
          current: proteinGrams,
          target: proteinTarget,
          color: AppTheme.proteinColor,
        ),
        const SizedBox(height: 24),
        _buildMacroBar(
          context,
          label: 'Carbohidratos',
          current: carbGrams,
          target: carbTarget,
          color: AppTheme.carbColor,
        ),
        const SizedBox(height: 24),
        _buildMacroBar(
          context,
          label: 'Grasas',
          current: fatGrams,
          target: fatTarget,
          color: AppTheme.fatColor,
        ),
      ],
    );
  }

  Widget _buildMacroBar(
      BuildContext context, {
        required String label,
        required double current,
        required double target,
        required Color color,
      }) {
    final percent = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${current.toInt()} / ${target.toInt()} g',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 12.0,
          percent: percent,
          animation: true,
          animateFromLastPercent: true,
          barRadius: const Radius.circular(6),
          progressColor: color,
          backgroundColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}