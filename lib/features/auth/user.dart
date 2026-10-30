import '../../core/config.dart';

class User {
  User({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.noMiddleName,
    required this.avatar,
    required this.balance,
    required this.bonus,
  });

  final int id;
  final String phone;

  /// Есімі (username)
  final String firstName;

  /// Тегі (l_name)
  final String lastName;

  /// Әкесінің аты (s_name)
  final String middleName;

  /// «Әкесінің аты жоқ» белгісі (s_name_not)
  final bool noMiddleName;

  /// Аватар суретінің толық адресі, жоқ болса — null
  final String? avatar;
  final num balance;
  final num bonus;

  /// «Айнұр Қалиева» — есімі мен тегі
  String get name => [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  /// «ID: 00385462» — 8 таңбаға дейін нөлмен толтырылады
  String get displayId => id.toString().padLeft(8, '0');

  factory User.fromJson(Map<String, dynamic> json) {
    String str(Object? v) => (v ?? '').toString().trim();
    final img = str(json['img1']);
    return User(
      id: json['id'] as int,
      phone: str(json['tel_num']),
      firstName: str(json['username']),
      lastName: str(json['l_name']),
      middleName: str(json['s_name']),
      noMiddleName: '${json['s_name_not']}' == '1',
      avatar: img.isEmpty ? null : avatarUrl(img),
      balance: num.tryParse('${json['balance']}') ?? 0,
      bonus: num.tryParse('${json['bonus']}') ?? 0,
    );
  }

  /// Сайттағыдай: {backend}/storage/files/images/avatars/{файл}
  static String avatarUrl(String file) {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base/storage/files/images/avatars/$file';
  }
}
