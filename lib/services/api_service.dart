import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/utils/image_compressor.dart';
import '../models/meal_model.dart';
import '../models/profile_model.dart';
import '../models/progress_model.dart';

class ApiService {
  final Dio _dio = Dio();

  final String _webhookUrl = dotenv.env['WEBHOOK_URL'] ?? '';
  final String _bearerToken = dotenv.env['BEARER_TOKEN'] ?? '';
  final String mediaBaseUrl = dotenv.env['MEDIA_BASE_URL'] ?? '';
  final String _mediaToken = dotenv.env['MEDIA_TOKEN'] ?? '';

  String? _currentUserEmail;

  ApiService() {
    _dio.options.baseUrl = _webhookUrl;
    _dio.options.headers['Authorization'] = 'Bearer $_bearerToken';
    _dio.options.connectTimeout = const Duration(seconds: 30);
  }

  // --- SESIÓN Y PERSISTENCIA (SISTEMA OTP) ---

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token');
    final email = prefs.getString('user_email');

    if (token != null && token.isNotEmpty) {
      _dio.options.headers['session-token'] = token;
      _currentUserEmail = email;
    }
  }

  bool get hasSession => _dio.options.headers.containsKey('session-token');

  String? getCurrentEmail() => _currentUserEmail;

  Future<bool> requestPin(String email) async {
    try {
      final response = await _dio.post('auth/request', data: {'email': email.trim()});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyPin(String email, String pin) async {
    try {
      final response = await _dio.post('auth/verify', data: {
        'email': email.trim(),
        'pin': pin.trim()
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_token', token);
        await prefs.setString('user_email', email.trim());

        _dio.options.headers['session-token'] = token;
        _currentUserEmail = email.trim();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('user_email');
    _dio.options.headers.remove('session-token');
    _currentUserEmail = null;
  }

  // --- MÉTODOS DE PERFIL ---

  Future<ProfileModel?> getProfile() async {
    try {
      final response = await _dio.get('profile');
      if (response.data == null) return null;
      if (response.data is List && response.data.isNotEmpty) {
        final res =
            response.data.first is Map &&
                response.data.first.containsKey('resultado')
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
    await _dio.post(
      'profile/update',
      data: {
        'tdee_objetivo': tdee,
        'meta_proteinas': proteinas,
        'meta_carbos': carbos,
        'meta_grasas': grasas,
      },
    );
  }

  // --- MÉTODOS DE COMIDAS E IA ---

  Future<MealModel> sendText(String text) async {
    final response = await _dio.post('ai', data: {'texto': text});
    return MealModel.fromJson(response.data);
  }

  // CAMBIO: Recibe dynamic (XFile) para funcionar en Web y Android
  Future<MealModel> sendImage(dynamic image) async {
    FormData formData;

    if (kIsWeb) {
      // En Web extraemos bytes en memoria (sin usar dart:io ni ImageCompressor)
      final bytes = await image.readAsBytes();
      formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: image.name ?? 'meal.jpg',
        ),
      });
    } else {
      // En Android usamos File y tu compresor
      final File fileImage = File(image.path);
      final compressed = await ImageCompressor.compress(fileImage);
      formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressed.path,
          filename: compressed.path.split('/').last,
        ),
      });
    }

    final response = await _dio.post('ai', data: formData);
    return MealModel.fromJson(response.data);
  }

  Future<List<MealModel>> getMealsHistory(String period) async {
    final response = await _dio.get('history/$period');
    List data =
        (response.data is List &&
            response.data.isNotEmpty &&
            response.data.first is Map &&
            response.data.first.containsKey('resultado'))
        ? response.data.first['resultado']
        : response.data;
    return (data).map((json) => MealModel.fromJson(json)).toList();
  }

  Future<void> deleteMeal(int id) async =>
      await _dio.delete('delete', data: {'id': id});

  // --- MÉTODOS DE PROGRESO ---

  Future<List<ProgressModel>> getProgressHistory() async {
    final response = await _dio.get('progress/history');
    List data =
        (response.data is List &&
            response.data.isNotEmpty &&
            response.data.first is Map &&
            response.data.first.containsKey('resultado'))
        ? response.data.first['resultado']
        : response.data;
    return (data).map((json) => ProgressModel.fromJson(json)).toList();
  }

  Future<void> addWeightRecord(double weight) async =>
      await _dio.post('progress/add', data: {'peso_corporal': weight});

  // CAMBIO: Recibe dynamic (XFile)
  Future<void> uploadProgressPhoto(int id, dynamic photo) async {
    FormData formData;

    if (kIsWeb) {
      final bytes = await photo.readAsBytes();
      formData = FormData.fromMap({
        'id': id.toString(),
        'file': MultipartFile.fromBytes(
          bytes,
          filename: photo.name ?? 'progress.jpg',
        ),
      });
    } else {
      final File filePhoto = File(photo.path);
      String fileName = filePhoto.path.split('/').last;
      formData = FormData.fromMap({
        'id': id.toString(),
        'file': await MultipartFile.fromFile(
          filePhoto.path,
          filename: fileName,
        ),
      });
    }

    await _dio.post('progress/upload-photo', data: formData);
  }

  Map<String, String> get mediaHeaders => {'apptoken': _mediaToken};

  Future<void> deleteWeightRecord(int id) async =>
      await _dio.delete('progress/delete', data: {'id': id});
}
