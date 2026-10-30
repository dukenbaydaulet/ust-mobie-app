import 'dart:io' show Platform;

class AppConfig {
  static const version = '2.4.0';

  /// Құпиялылық саясаты — дүкендер талабы (мәтіні: docs/privacy-policy.md).
  /// Сайтта осы мекенжаймен жариялану керек.
  static const privacyPolicyUrl = 'https://ust.kz/privacy';

  /// Қолдану ережелері. Сайтта бөлек бет болмағанша — құпиялылық саясаты.
  static const termsUrl = privacyPolicyUrl;

  /// «Көмек алу» — қолдау қызметінің WhatsApp-ы (+7 (771) 234-55-99)
  static const supportWhatsApp = 'https://wa.me/77712345599';

  /// Материалдарды backend-тен емес, сынақ деректерінен алу:
  /// flutter run --dart-define=MOCK_MATERIALS=true
  static const mockMaterials = bool.fromEnvironment('MOCK_MATERIALS');

  /// Нақты сервер (сайтпен ортақ)
  static const productionApiUrl = 'https://api.ust.kz/api';

  /// Backend адресі. Әдепкі — нақты сервер.
  /// Компьютердегі жергілікті серверді (ust-backend) қолдану:
  ///   flutter run --dart-define=API_URL=local
  /// Басқа адрес: flutter run --dart-define=API_URL=http://192.168.1.10:8000/api
  static String get apiUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isEmpty) return productionApiUrl;
    if (fromEnv == 'local') {
      // Android эмуляторы үшін компьютердің 127.0.0.1 адресі — 10.0.2.2
      return Platform.isAndroid
          ? 'http://10.0.2.2:8000/api'
          : 'http://127.0.0.1:8000/api';
    }
    return fromEnv;
  }
}
