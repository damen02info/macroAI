import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/utils/image_compressor.dart';
import '../models/meal_model.dart';
import '../models/profile_model.dart';
import '../models/progress_model.dart';

class ApiService {
  final Dio _dio = Dio();

  final String _webhookUrl = dotenv.env['N8N_WEBHOOK_URL'] ?? '';
  final String _bearerToken = dotenv.env['N8N_BEARER_TOKEN'] ?? '';
  final String mediaBaseUrl = dotenv.env['MEDIA_BASE_URL'] ?? '';
  final String _mediaToken = dotenv.env['MEDIA_TOKEN'] ?? '';

  ApiService() {
    _dio.options.baseUrl = _webhookUrl;
    _dio.options.headers['Authorization'] = 'Bearer $_bearerToken';
    _dio.options.connectTimeout = const Duration(seconds: 30);
  }

  // --- SESIÓN Y PERSISTENCIA ---

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && email.isNotEmpty) {
      _dio.options.headers['user-email'] = email;
    }
  }

  Future<void> setSessionEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    _dio.options.headers['user-email'] = email;
  }

  String? getCurrentEmail() {
    return _dio.options.headers['user-email']?.toString();
  }

  // --- MÉTODOS DE PERFIL ---

  Future<ProfileModel?> getProfile() async {
    try {
      final response = await _dio.get('profile');
      if (response.data == null) return null;
      if (response.data is List && response.data.isNotEmpty) {
        final res = response.data.first is Map && response.data.first.containsKey('resultado')
            ? response.data.first['resultado'].first
            : response.data.first;
        return ProfileModel.fromJson(res);
      }
      return ProfileModel.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    required double tdee,
    required double proteinas,
    required double carbos,
    required double grasas,
  }) async {
    await _dio.post('profile/update', data: {
      'tdee_objetivo': tdee,
      'meta_proteinas': proteinas,
      'meta_carbos': carbos,
      'meta_grasas': grasas
    });
  }

  // --- MÉTODOS DE COMIDAS E IA ---

  Future<MealModel> sendText(String text) async {
    final response = await _dio.post('ai', data: {'texto': text});
    return MealModel.fromJson(response.data);
  }

  Future<MealModel> sendImage(File image) async {
    final compressed = await ImageCompressor.compress(image);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        compressed.path,
        filename: compressed.path.split('/').last,
      ),
    });

    final response = await _dio.post('ai', data: formData);

    return MealModel.fromJson(response.data);
  }

  Future<List<MealModel>> getMealsHistory(String period) async {
    final response = await _dio.get('history/$period');
    List data = (response.data is List && response.data.isNotEmpty && response.data.first is Map && response.data.first.containsKey('resultado'))
        ? response.data.first['resultado']
        : response.data;
    return (data).map((json) => MealModel.fromJson(json)).toList();
  }

  Future<void> deleteMeal(int id) async => await _dio.delete('delete', data: {'id': id});

  // --- MÉTODOS DE PROGRESO ---

  Future<List<ProgressModel>> getProgressHistory() async {
    final response = await _dio.get('progress/history');
    List data = (response.data is List && response.data.isNotEmpty && response.data.first is Map && response.data.first.containsKey('resultado'))
        ? response.data.first['resultado']
        : response.data;
    return (data).map((json) => ProgressModel.fromJson(json)).toList();
  }

  Future<void> addWeightRecord(double weight) async => await _dio.post('progress/add', data: {'peso_corporal': weight});

  Future<void> uploadProgressPhoto(int id, File photo) async {
    String fileName = photo.path.split('/').last;
    FormData formData = FormData.fromMap({
      'id': id.toString(),
      'file': await MultipartFile.fromFile(photo.path, filename: fileName),
    });
    await _dio.post('progress/upload-photo', data: formData);
  }

  Map<String, String> get mediaHeaders => {
    'apptoken': _mediaToken,
  };

  Future<void> deleteWeightRecord(int id) async => await _dio.delete('progress/delete', data: {'id': id});
}