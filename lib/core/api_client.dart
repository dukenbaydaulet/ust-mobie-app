import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ),
  );
  return dio;
});

bool isUnauthorized(Object e) =>
    e is DioException && e.response?.statusCode == 401;

/// Пайдаланушыға көрсетуге болатын хабары бар қате.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Backend қатесінен адамға түсінікті хабарлама алу.
String errorMessage(Object e) {
  if (e is AppException) return e.message;
  if (e is DioException) {
    var data = e.response?.data;
    // Файл жүктегенде қате денесі байт болып келеді
    if (data is List<int>) {
      try {
        data = jsonDecode(utf8.decode(data));
      } catch (_) {}
    }
    if (data is Map) {
      for (final key in [
        'password',
        'passwordConfirm',
        'phone',
        'message',
        'error',
      ]) {
        final v = data[key];
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v is String) return v;
      }
    }
    switch (e.response?.statusCode) {
      case 401:
        return 'Кабинетке қайта кіріңіз';
      case 404:
        return 'Табылмады';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Серверге қосылу мүмкін емес';
    }
  }
  return 'Қате орын алды';
}
