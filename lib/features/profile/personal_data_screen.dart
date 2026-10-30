import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/typography.dart';
import '../../core/api_client.dart';
import '../auth/auth_controller.dart';
import '../materials/widgets/material_widgets.dart';
import 'profile_repository.dart';
import 'profile_screen.dart' show UserAvatar;
import 'widgets/profile_widgets.dart';

/// «Жеке деректер»: сурет, аты-жөні, телефон, құпия сөз, кабинетті жою.
class PersonalDataScreen extends ConsumerStatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  ConsumerState<PersonalDataScreen> createState() => _PersonalDataState();
}

class _PersonalDataState extends ConsumerState<PersonalDataScreen> {
  final _last = TextEditingController();
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).value;
    if (u != null) {
      _last.text = u.lastName;
      _first.text = u.firstName;
      _middle.text = u.noMiddleName ? '' : u.middleName;
      _phone.text = u.phone;
    }
  }

  @override
  void dispose() {
    _last.dispose();
    _first.dispose();
    _middle.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    // Backend 2 МБ-қа дейін қабылдайды — сурет кішірейтіліп жіберіледі
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(profileRepositoryProvider).uploadPhoto(file.path);
      await ref.read(authProvider.notifier).reload();
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _save() async {
    final first = _first.text.trim();
    final last = _last.text.trim();
    if (first.isEmpty || last.isEmpty) {
      showMessage(context, 'Тегіңіз бен есіміңізді толтырыңыз');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            firstName: first,
            lastName: last,
            middleName: _middle.text.trim(),
          );
      await ref.read(authProvider.notifier).reload();
      if (!mounted) return;
      showMessage(context, 'Өзгерістер сақталды');
      context.pop();
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      backgroundColor: MColors.page,
      body: Column(
        children: [
          const ProfileTopBar(title: 'Жеке деректер'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _AvatarPicker(
                  url: user?.avatar,
                  loading: _uploading,
                  onTap: _pickPhoto,
                ),
                const SizedBox(height: 16),
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.badge,
                            size: 20,
                            color: MColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Жеке мәліметтер',
                              style: PText.cardTitle,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: const ShapeDecoration(
                              color: Color(0xFFEFF4FF),
                              shape: StadiumBorder(),
                            ),
                            child: Text(
                              'Мұғалім кабинеті',
                              style: AppText.tag.copyWith(
                                color: const Color(0xFF004BC0),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        label: 'Тегіңіз (Фамилия)',
                        controller: _last,
                        icon: Symbols.person,
                      ),
                      _Field(
                        label: 'Есіміңіз',
                        controller: _first,
                        icon: Symbols.person,
                      ),
                      _Field(
                        label: 'Әкеңіздің аты (міндетті емес)',
                        controller: _middle,
                        icon: Symbols.person,
                      ),
                      _Field(
                        label: 'Телефон нөмірі',
                        controller: _phone,
                        icon: Symbols.call,
                        enabled: false,
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Қауіпсіздік',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    height: 20 / 15,
                    color: AppText.ink,
                  ),
                ),
                const SizedBox(height: 8),
                WhiteCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showChangePasswordDialog(context),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 12, 16),
                      child: Row(
                        children: [
                          IconBox(
                            icon: Symbols.lock_reset,
                            background: Color(0xFFE6EEFF),
                            size: 44,
                            circle: true,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Құпия сөзді өзгерту',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 20 / 15,
                                color: AppText.ink,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppText.muted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                BigButton(
                  label: 'Өзгерістерді сақтау',
                  icon: Symbols.done_all,
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Болдырмау',
                      style: AppText.action.copyWith(
                        color: AppText.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/profile/delete'),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: Row(
                      children: [
                        IconBox(
                          icon: Symbols.no_accounts,
                          color: AppText.muted,
                          background: Color(0xFFE9EDF3),
                          size: 50,
                          circle: true,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Кабинетті жою',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  height: 20 / 14,
                                  color: AppText.slate,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Осы кабинетке тіркелген барлық ақпарат жойылып кетеді',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  height: 16 / 12,
                                  color: AppText.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppText.muted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.url,
    required this.loading,
    required this.onTap,
  });
  final String? url;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: loading ? null : onTap,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                UserAvatar(url: url, size: 100),
                if (loading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: MColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Symbols.photo_camera,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: loading ? null : onTap,
          child: Text(
            'Суретті өзгерту',
            style: AppText.action.copyWith(
              color: MColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'JPG, PNG немесе WebP (макс. 5 МБ)',
          style: PText.small.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

/// Атауы үстінде тұратын өріс: сол жағында белгіше.
class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.enabled = true,
    this.last = false,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final bool last;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    // InputDecoration-ның prefixIcon-ы өз шегінісін қосады — белгіше мен
    // мәтіннің арасы дәл 8 болуы үшін өрісті өзіміз құрамыз.
    return Padding(
      padding: EdgeInsets.only(bottom: widget.last ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: PText.fieldLabel.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: enabled ? _focus.requestFocus : null,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: enabled ? Colors.white : PColors.disabled,
                borderRadius: BorderRadius.circular(10),
                border: enabled
                    ? Border.all(
                        color: _focus.hasFocus
                            ? MColors.primary
                            : MColors.border,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: enabled ? AppText.slate : AppText.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      enabled: enabled,
                      textCapitalization: TextCapitalization.words,
                      style: AppText.input.copyWith(
                        fontSize: 16,
                        height: 20 / 16,
                        color: enabled ? AppText.ink : AppText.muted,
                      ),
                      decoration: const InputDecoration.collapsed(
                        hintText: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Құпия сөзді өзгерту
// ============================================================

Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog(
    context: context,
    useRootNavigator: true,
    builder: (_) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends ConsumerState<_ChangePasswordDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = _old.text.isEmpty
        ? 'Қазіргі құпия сөзді енгізіңіз'
        : _new.text.length < 4
        ? 'Жаңа құпия сөз кемінде 4 таңбадан тұруы керек'
        : _new.text != _repeat.text
        ? 'Құпия сөздер сәйкес келмейді'
        : null;
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(_old.text, _new.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, 'Құпия сөз өзгертілді');
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = errorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: IconBox(icon: Symbols.lock_reset, size: 52, circle: true),
            ),
            const SizedBox(height: 12),
            const Text(
              'Құпия сөзді өзгерту',
              textAlign: TextAlign.center,
              style: PText.cardTitle,
            ),
            const SizedBox(height: 16),
            PasswordField(label: 'Қазіргі құпия сөз', controller: _old),
            const SizedBox(height: 12),
            PasswordField(label: 'Жаңа құпия сөз', controller: _new),
            const SizedBox(height: 12),
            PasswordField(
              label: 'Жаңа құпия сөзді қайталаңыз',
              controller: _repeat,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: PText.small.copyWith(color: PColors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            BigButton(label: 'Сақтау', loading: _saving, onPressed: _submit),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Бас тарту',
                style: AppText.action.copyWith(color: AppText.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Құпия сөз өрісі: құлып белгішесі, көз батырмасы.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.onSubmitted,
  });
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: MColors.border),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: PText.fieldLabel),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          onSubmitted: widget.onSubmitted,
          style: AppText.input.copyWith(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(
              Symbols.lock,
              size: 18,
              color: AppText.muted,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(
                _hidden ? Symbols.visibility_off : Symbols.visibility,
                size: 18,
                color: AppText.muted,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: MColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
