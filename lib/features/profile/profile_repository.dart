import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../auth/auth_controller.dart';

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.read(dioProvider)),
);

/// Белсенді жазылым. Жоқ болса — null.
final subscriptionProvider = FutureProvider.autoDispose<Subscription?>((ref) {
  // Кабинеттен шыққанда / басқа адам кіргенде қайта сұралады
  final user = ref.watch(authProvider).value;
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).subscription();
});

/// Жазылым (сайттағы qauimdastyq_users жолы).
class Subscription {
  const Subscription({
    required this.plan,
    required this.from,
    required this.to,
  });

  /// day | month | year — тарифтер терезесіндегі id-лермен бірдей
  final String plan;
  final DateTime from;
  final DateTime to;

  int get daysLeft => to.difference(DateTime.now()).inDays.clamp(0, 99999);

  /// Қалған уақыттың үлесі: 0..1
  double get leftShare {
    final total = to.difference(from).inSeconds;
    if (total <= 0) return 0;
    return (to.difference(DateTime.now()).inSeconds / total).clamp(0.0, 1.0);
  }

  String get title => switch (plan) {
    'day' => '1 күндік тариф',
    'month' => 'Айлық тариф',
    _ => 'Жылдық тариф',
  };
}

/// Төлем тарихының жолы.
class Payment {
  const Payment({required this.date, required this.title, required this.sum});
  final String date;
  final String title;
  final int sum;
}

class ProfileRepository {
  ProfileRepository(this._dio);
  final Dio _dio;

  /// Сайттың «Жеке мәліметтер» формасы (profile/change).
  /// Аты-жөнін өзгерту саны шектеулі — backend қате хабарын қайтарады.
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String middleName,
  }) async {
    // profile/change барлық өрісті жаңартады — қалғандары бұрынғыдай қалсын
    final res = await _dio.get('/profile/getUserInfo');
    final u = Map<String, dynamic>.from(res.data['user'] as Map);
    await _dio.post(
      '/profile/change',
      data: {
        'username': firstName,
        'l_name': lastName,
        's_name': middleName.isEmpty ? null : middleName,
        's_name_not': middleName.isEmpty ? 1 : 0,
        'jsn': u['jsn'],
        'text_info': u['text_info'],
        'ulty': u['ulty'],
        'jynysy': u['jynysy'],
        'tugan_kun': u['tugan_kun'],
        'province_id': u['province_id'],
        'district_id': u['district_id'],
        'school_id': u['school_id'],
        'work_not': u['work_not'],
      },
    );
  }

  Future<void> uploadPhoto(String path) async {
    await _dio.post(
      '/profile/change/photo',
      data: FormData.fromMap({'file': await MultipartFile.fromFile(path)}),
    );
  }

  /// Ескі құпия сөз қате болса — backend «oldPassword» қатесін қайтарады.
  Future<void> changePassword(String oldPassword, String password) async {
    final data = {
      'oldPassword': oldPassword,
      'password': password,
      'passwordConfirm': password,
    };
    try {
      // Мобильді endpoint 4 таңбаны қабылдайды; серверде әлі жоқ болса —
      // сайттың endpoint-і (кемінде 8 таңба)
      try {
        await _dio.post('/mobile/profile/password', data: data);
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        await _dio.post('/auth/reset-password', data: data);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final errors = data is Map ? data['errors'] : null;
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        throw AppException(first is List ? '${first.first}' : '$first');
      }
      rethrow;
    }
  }

  /// Құпия сөзді тексереді (кіру endpoint-і арқылы, токен сақталмайды).
  Future<bool> checkPassword(String phone, String password) async {
    try {
      await _dio.post(
        '/auth/login',
        data: {'phone': phone, 'password': password},
      );
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 422) return false;
      rethrow;
    }
  }

  /// Аккаунтты жою. Backend-те әлі жоқ — 404 болса, түсінікті хабар.
  Future<void> deleteAccount(String password) async {
    try {
      await _dio.post('/mobile/account/delete', data: {'password': password});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const AppException(
          'Аккаунтты жою әзірге серверде қосылмаған. Қолдау қызметіне жазыңыз',
        );
      }
      rethrow;
    }
  }

  /// Ең ұзақ жарамды «Материал» (6) немесе күндік (1) тариф.
  Future<Subscription?> subscription() async {
    final res = await _dio.get('/word/tarifter/checkSub');
    final now = DateTime.now();
    Subscription? best;
    for (final t in (res.data['tarifs'] as List? ?? const [])) {
      final id = int.tryParse('${t['id']}');
      final from = DateTime.tryParse('${t['from_date']}');
      final to = DateTime.tryParse('${t['to_date']}');
      if ((id != 1 && id != 6) || from == null || to == null) continue;
      if (to.isBefore(now)) continue;
      final days = to.difference(from).inDays;
      final plan = id == 1 ? 'day' : (days >= 300 ? 'year' : 'month');
      if (best == null || to.isAfter(best.to)) {
        best = Subscription(plan: plan, from: from, to: to);
      }
    }
    return best;
  }

  /// Тариф төлемдері (сайттағы «Төлем тарихы»).
  Future<List<Payment>> payments() async {
    final res = await _dio.get('/profile/qauymdastyq/history');
    return [
      for (final p in (res.data['history'] as List? ?? const []))
        Payment(
          date: '${p['date']}'.split(' / ').first,
          title: '${p['type']}',
          sum: int.tryParse('${p['sum']}') ?? 0,
        ),
    ];
  }

  /// Жазылымды тоқтату. Backend-те әлі жоқ — 404 болса, түсінікті хабар.
  Future<void> cancelSubscription() async {
    try {
      await _dio.post('/mobile/subscription/cancel');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const AppException(
          'Жазылымды тоқтату әзірге серверде қосылмаған. Қолдау қызметіне жазыңыз',
        );
      }
      rethrow;
    }
  }
}

// ============================================================
// Баптаулар (телефонда сақталады)
// ============================================================

const _storageChannel = MethodChannel('kz.ust/storage');

/// Телефондағы бос орын (байт). Белгісіз болса — null.
final freeSpaceProvider = FutureProvider.autoDispose<int?>((ref) async {
  try {
    return await _storageChannel.invokeMethod<int>('freeBytes');
  } catch (_) {
    return null;
  }
});

/// «Офлайн сақтау»: жүктелген файлдар телефонда сақталады.
final offlineSaveProvider = NotifierProvider<BoolSetting, bool>(
  () => BoolSetting(offlineSaveKey, true),
);

/// «Хабарландырулар»
final notificationsProvider = NotifierProvider<BoolSetting, bool>(
  () => BoolSetting('notifications', true),
);

const offlineSaveKey = 'offline_save';

class BoolSetting extends Notifier<bool> {
  BoolSetting(this.key, this.initial);
  final String key;
  final bool initial;

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(key);
      if (v != null && v != state) state = v;
    });
    return initial;
  }

  Future<void> set(bool value) async {
    state = value;
    await (await SharedPreferences.getInstance()).setBool(key, value);
  }
}

/// «25.09.2027»
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year}';
