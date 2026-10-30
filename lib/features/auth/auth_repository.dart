import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import 'user.dart';

final authRepositoryProvider = Provider(
  (ref) =>
      AuthRepository(ref.read(dioProvider), ref.read(tokenStorageProvider)),
);

class AuthRepository {
  AuthRepository(this._dio, this._storage);
  final Dio _dio;
  final TokenStorage _storage;

  /// phone форматы: +7(705) 123-45-67
  Future<void> login(String phone, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'phone': phone, 'password': password},
    );
    await _storage.save(res.data['access_token'] as String);
  }

  /// true — нөмір тіркелген (құпия сөз сұраймыз), false — жаңа пайдаланушы.
  Future<bool> isRegistered(String phone) async {
    final res = await _dio.post(
      '/auth/login/check-phone',
      data: {'phone': phone},
    );
    return res.data['loginOpen'] == 2;
  }

  Future<void> register(
    String phone,
    String password,
    String passwordConfirm,
  ) async {
    await _dio.post(
      '/auth/login/create-user',
      data: {
        'phone': phone,
        'password': password,
        'passwordConfirm': passwordConfirm,
      },
    );
  }

  /// Нөмірге WhatsApp немесе SMS арқылы жаңа құпия сөз жібереді.
  /// false — нөмір тіркелмеген.
  Future<bool> sendPasswordSms(String phone) async {
    final res = await _dio.post(
      '/auth/reset-password/send-sms',
      data: {'phone': phone},
    );
    return res.data['success'] == true;
  }

  Future<User?> currentUser() async {
    if (await _storage.read() == null) return null;
    try {
      final res = await _dio.get('/auth/user');
      return User.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Токен ескірген болса да, жергілікті түрде шығамыз
    }
    await _storage.clear();
  }
}
