import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneMask {
  /// Экранда көрсетілетін формат: +7 (775) 489 - 12 - 34
  static MaskTextInputFormatter formatter() => MaskTextInputFormatter(
    mask: '+7 (###) ### - ## - ##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  /// 10 цифр, Қазақстан нөмірі 7-ден басталады (7xx)
  static bool isValid(String digits) =>
      digits.length == 10 && digits.startsWith('7');

  /// Backend-тегі формат (tel_num): +7(775) 489-12-34
  static String toBackend(String d) =>
      '+7(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6, 8)}-${d.substring(8)}';
}
