import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService apiService;

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

  Future<void> saveProfile(double tdee, double pro, double carb, double fat) async {
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

  // CAMBIO: Recibe dynamic
  Future<void> processImageInput(dynamic image) async {
    _setLoading(true);
    try {
      final meal = await apiService.sendImage(image);
      _addMealToUI(meal);
    } finally {
      _setLoading(false);
    }
  }

  void _addMealToUI(MealModel meal) {
    todaysMeals.add(meal);
    if (currentPeriod == 'day') historyMeals.add(meal);
    notifyListeners();
  }

  Future<void> deleteMeal(int id) async {
    todaysMeals.removeWhere((m) => m.id == id);
    historyMeals.removeWhere((m) => m.id == id);
    notifyListeners();
    await apiService.deleteMeal(id);
  }

  Map<String, List<MealModel>> get groupedHistoryMeals {
    final sorted = [...historyMeals]
      ..sort((a, b) => DateTime.parse(b.fechaHora).compareTo(DateTime.parse(a.fechaHora)));

    if (currentPeriod == 'day') {
      return {'': sorted};
    }

    final groups = <String, List<MealModel>>{};

    for (final meal in sorted) {
      final fecha = DateTime.parse(meal.fechaHora);

      late final String key;

      if (currentPeriod == 'week') {
        key = DateFormat(
          'EEEE d MMMM',
          'es_ES',
        ).format(fecha);
      } else {
        final monday = fecha.subtract(Duration(days: fecha.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));

        key =
        'Semana ${DateFormat('d MMM').format(monday)} - ${DateFormat('d MMM').format(sunday)}';
      }

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(meal);
    }

    return groups;
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }
}