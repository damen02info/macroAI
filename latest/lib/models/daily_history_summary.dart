import 'package:flutter/material.dart';
import 'meal_model.dart';

class DailyHistorySummary {
  final String dateKey;
  final List<MealModel> meals;
  final double consumedKcal;
  final double consumedProtein;
  final double consumedCarb;
  final double consumedFat;
  final double targetKcal;
  final double targetProtein;
  final double targetCarb;
  final double targetFat;

  DailyHistorySummary({
    required this.dateKey,
    required this.meals,
    required this.consumedKcal,
    required this.consumedProtein,
    required this.consumedCarb,
    required this.consumedFat,
    required this.targetKcal,
    required this.targetProtein,
    required this.targetCarb,
    required this.targetFat,
  });
}
