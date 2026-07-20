import 'dart:io';
import 'package:flutter/material.dart';
import '../models/progress_model.dart';
import '../services/api_service.dart';

class ProgressProvider extends ChangeNotifier {
  final ApiService apiService;

  List<ProgressModel> weightHistory = [];
  bool isLoading = false;

  ProgressProvider(this.apiService);

  Future<void> fetchHistory() async {
    _setLoading(true);
    try {
      weightHistory = await apiService.getProgressHistory();
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addWeight(double weight) async {
    _setLoading(true);
    try {
      await apiService.addWeightRecord(weight);
      await fetchHistory();
    } catch (e) {
      debugPrint("Error adding weight: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadPhotoToRecord(int id, File photo) async {
    _setLoading(true);
    try {
      await apiService.uploadProgressPhoto(id, photo);
      await fetchHistory();
    } catch (e) {
      debugPrint("Error uploading photo: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteWeight(int id) async {
    weightHistory.removeWhere((w) => w.id == id);
    notifyListeners();
    try {
      await apiService.deleteWeightRecord(id);
    } catch (e) {
      await fetchHistory();
      debugPrint("Error deleting weight: $e");
    }
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }
}