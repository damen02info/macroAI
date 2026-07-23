import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_model.dart';
import '../models/profile_model.dart'; // Import ProfileModel
import '../models/daily_history_summary.dart'; // Import DailyHistorySummary
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService apiService;

  List<ProfileModel> _profileHistory = []; // Add profile history

  // --- ESTADO PERFIL ---
  double targetKcal = 2200;
  double proteinTarget = 160;
  double carbTarget = 220;
  double fatTarget = 70;
  String lastUpdated = '';

  // --- ESTADO HISTORIAL ---
  List<MealModel> todaysMeals = [];
  List<MealModel> historyMeals = [];
  String currentPeriod = 'day';
  bool isLoading = false;

  DashboardProvider(this.apiService);

  // --- GETTERS ---
  double get consumedKcal => todaysMeals.fold(0, (s, i) => s + i.calorias);

  double get proteinGrams => todaysMeals.fold(0, (s, i) => s + i.proteinas);

  double get carbGrams => todaysMeals.fold(0, (s, i) => s + i.carbohidratos);

  double get fatGrams => todaysMeals.fold(0, (s, i) => s + i.grasas);

  // --- INICIALIZACIÓN ---
  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      targetKcal = prefs.getDouble('tdee') ?? 2200;
      proteinTarget = prefs.getDouble('pro') ?? 160;
      carbTarget = prefs.getDouble('carb') ?? 220;
      fatTarget = prefs.getDouble('fat') ?? 70;
      lastUpdated = prefs.getString('lastUpdated') ?? '';

      _syncProfile();
      todaysMeals = await apiService.getMealsHistory('day');
      await changeHistoryPeriod('day');
      _profileHistory = await apiService
          .getProfileHistory();
      _profileHistory.sort(
        (a, b) => DateTime.parse(
          a.actualizadoEn,
        ).compareTo(DateTime.parse(b.actualizadoEn)),
      );
    } catch (e) {
      debugPrint("Error loadInitialData: $e");
    } finally {
      _setLoading(false);
    }
  }

  // --- MÉTODOS PERFIL ---
  Future<void> _syncProfile() async {
    final profile = await apiService.getProfile();
    if (profile != null) {
      targetKcal = profile.tdeeObjetivo;
      proteinTarget = profile.metaProteinas;
      carbTarget = profile.metaCarbos;
      fatTarget = profile.metaGrasas;
      lastUpdated = profile.actualizadoEn;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tdee', targetKcal);
      await prefs.setDouble('pro', proteinTarget);
      await prefs.setDouble('carb', carbTarget);
      await prefs.setDouble('fat', fatTarget);
      await prefs.setString('lastUpdated', lastUpdated);
      notifyListeners();
    }
  }

  Future<void> saveProfile(
    double tdee,
    double pro,
    double carb,
    double fat,
  ) async {
    await apiService.updateProfile(
      tdee: tdee,
      proteinas: pro,
      carbos: carb,
      grasas: fat,
    );
    targetKcal = tdee;
    proteinTarget = pro;
    carbTarget = carb;
    fatTarget = fat;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tdee', tdee);
    await prefs.setDouble('pro', pro);
    await prefs.setDouble('carb', carb);
    await prefs.setDouble('fat', fat);
    _syncProfile();
    notifyListeners();
  }

  // --- MÉTODOS COMIDAS ---
  Future<void> changeHistoryPeriod(String period) async {
    currentPeriod = period;
    _setLoading(true);
    try {
      historyMeals = await apiService.getMealsHistory(period);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> processTextInput(String text) async {
    if (text.trim().isEmpty) return;
    _setLoading(true);
    try {
      final meal = await apiService.sendText(text);
      _addMealToUI(meal);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> processImageInput(dynamic image) async {
    _setLoading(true);
    try {
      final meal = await apiService.sendImage(image);
      _addMealToUI(meal);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _addMealToUI(MealModel meal) async {
    todaysMeals.add(meal);
    await changeHistoryPeriod(currentPeriod);
  }

  Future<void> deleteMeal(int id) async {
    todaysMeals.removeWhere((m) => m.id == id);
    historyMeals.removeWhere((m) => m.id == id);
    notifyListeners();
    await apiService.deleteMeal(id);
  }

  Map<String, DailyHistorySummary> get groupedHistoryMeals {
    final sorted = [...historyMeals]
      ..sort(
        (a, b) =>
            DateTime.parse(b.fechaHora).compareTo(DateTime.parse(a.fechaHora)),
      );

    if (currentPeriod == 'day') {
      final mealsForToday = sorted.where((meal) {
        final mealDate = DateTime.parse(meal.fechaHora).toLocal();
        final today = DateTime.now().toLocal();
        return mealDate.year == today.year &&
            mealDate.month == today.month &&
            mealDate.day == today.day;
      }).toList();

      final currentTargets = _getCurrentTargets();

      final consumedKcal = mealsForToday.fold(
        0.0,
        (sum, item) => sum + item.calorias,
      );
      final consumedProtein = mealsForToday.fold(
        0.0,
        (sum, item) => sum + item.proteinas,
      );
      final consumedCarb = mealsForToday.fold(
        0.0,
        (sum, item) => sum + item.carbohidratos,
      );
      final consumedFat = mealsForToday.fold(
        0.0,
        (sum, item) => sum + item.grasas,
      );

      return {
        '': DailyHistorySummary(
          dateKey: '',
          meals: mealsForToday,
          consumedKcal: consumedKcal,
          consumedProtein: consumedProtein,
          consumedCarb: consumedCarb,
          consumedFat: consumedFat,
          targetKcal: currentTargets.tdeeObjetivo,
          targetProtein: currentTargets.metaProteinas,
          targetCarb: currentTargets.metaCarbos,
          targetFat: currentTargets.metaGrasas,
        ),
      };
    }

    final groups = <String, List<MealModel>>{};

    for (final meal in sorted) {
      final fecha = DateTime.parse(meal.fechaHora);

      late final String key;

      if (currentPeriod == 'week') {
        key = DateFormat('EEEE d MMMM', 'es_ES').format(fecha);
      } else if (currentPeriod == 'month') {
        final monday = fecha.subtract(Duration(days: fecha.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));

        key =
            'Semana ${DateFormat('d MMM').format(monday)} - ${DateFormat('d MMM').format(sunday)}';
      }

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(meal);
    }

    final Map<String, DailyHistorySummary> summaryGroups = {};
    for (final entry in groups.entries) {
      final mealsInGroup =
          entry.value;
      if (mealsInGroup.isEmpty) continue;

      final consumedKcal = mealsInGroup.fold(
        0.0,
        (sum, item) => sum + item.calorias,
      );
      final consumedProtein = mealsInGroup.fold(
        0.0,
        (sum, item) => sum + item.proteinas,
      );
      final consumedCarb = mealsInGroup.fold(
        0.0,
        (sum, item) => sum + item.carbohidratos,
      );
      final consumedFat = mealsInGroup.fold(
        0.0,
        (sum, item) => sum + item.grasas,
      );

      double finalTargetKcal = 0.0;
      double finalTargetProtein = 0.0;
      double finalTargetCarb = 0.0;
      double finalTargetFat = 0.0;

      if (currentPeriod == 'week') {
        final dateOfDay = DateTime.parse(
          mealsInGroup.first.fechaHora,
        ).toLocal();
        final dailyTargets = _getProfileTargetsForDate(dateOfDay);
        finalTargetKcal = dailyTargets.tdeeObjetivo;
        finalTargetProtein = dailyTargets.metaProteinas;
        finalTargetCarb = dailyTargets.metaCarbos;
        finalTargetFat = dailyTargets.metaGrasas;
      } else if (currentPeriod == 'month') {
        final DateFormat formatter = DateFormat('d MMM');
        final String dateString = entry.key
            .split(' - ')
            .first
            .replaceAll('Semana ', '');

        DateTime weekStartDate;
        try {
          weekStartDate = formatter.parse(dateString);
        } catch (e) {
          debugPrint(
            "Error parsing week start date from key: $e. Key: ${entry.key}",
          );
          weekStartDate = DateTime.now();
        }

        for (int i = 0; i < 7; i++) {
          final dayDate = weekStartDate.add(Duration(days: i));
          final dailyTargets = _getProfileTargetsForDate(dayDate);
          finalTargetKcal += dailyTargets.tdeeObjetivo;
          finalTargetProtein += dailyTargets.metaProteinas;
          finalTargetCarb += dailyTargets.metaCarbos;
          finalTargetFat += dailyTargets.metaGrasas;
        }
      }

      summaryGroups[entry.key] = DailyHistorySummary(
        dateKey: entry.key,
        meals: mealsInGroup,
        consumedKcal: consumedKcal,
        consumedProtein: consumedProtein,
        consumedCarb: consumedCarb,
        consumedFat: consumedFat,
        targetKcal: finalTargetKcal,
        targetProtein: finalTargetProtein,
        targetCarb: finalTargetCarb,
        targetFat: finalTargetFat,
      );
    }

    return summaryGroups;
  }

  ProfileModel _getCurrentTargets() {
    return ProfileModel(
      id: 0,
      tdeeObjetivo: targetKcal,
      metaProteinas: proteinTarget,
      metaCarbos: carbTarget,
      metaGrasas: fatTarget,
      actualizadoEn: DateTime.now().toIso8601String(),
    );
  }

  ProfileModel _getProfileTargetsForDate(DateTime date) {
    ProfileModel? closestProfile;

    for (final profile in _profileHistory) {
      final profileDate = DateTime.parse(profile.actualizadoEn).toLocal();
      if (profileDate.isBefore(date) || profileDate.isAtSameMomentAs(date)) {
        if (closestProfile == null ||
            DateTime.parse(
              closestProfile.actualizadoEn,
            ).isBefore(profileDate)) {
          closestProfile = profile;
        }
      }
    }

    return closestProfile ?? _getCurrentTargets();
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }
}
