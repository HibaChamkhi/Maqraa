import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import 'profile_theme.dart';
import 'teacher_profile_page.dart' show ProfileCard, InfoRow;
import 'web_shell.dart';

/// Web teacher settings (الإعدادات): all sections on one page — personal data
/// + change password (two columns), then notifications + sessions + devices.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: _SettingsView(user: user),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView({required this.user});
  final AppUser user;

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  int _tab = 0;
  static const _tabs = [
    'البيانات الشخصية',
    'تغيير كلمة المرور',
    'إشعارات',
    'الجلسات والأمان',
  ];

  @override
  Widget build(BuildContext context) {
    return WebShell(
      user: widget.user,
      current: 'الإعدادات',
      breadcrumb: 'الإعدادات / الأمان والبيانات الشخصية',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _TabBar(
            tabs: _tabs,
            current: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 20),
          _section(),
        ],
      ),
    );
  }

  /// Content for the currently-selected tab.
  Widget _section() {
    switch (_tab) {
      case 0:
        return _PersonalDataCard(user: widget.user);
      case 1:
        return const _PasswordCard();
      case 2:
        return const _NotificationsCard();
      default:
        return LayoutBuilder(builder: (context, c) {
          if (c.maxWidth >= 760) {
            return const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _DevicesCard()),
                  SizedBox(width: 16),
                  Expanded(child: _SessionsCard()),
                ],
              ),
            );
          }
          return const Column(
            children: [
              _SessionsCard(),
              SizedBox(height: 16),
              _DevicesCard(),
            ],
          );
        });
    }
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar(
      {required this.tabs, required this.current, required this.onSelect});
  final List<String> tabs;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProfileTheme.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: i == current ? ProfileTheme.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == current ? Colors.white : ProfileTheme.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Field row: label on the right, input on the left (RTL).
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.field});
  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: field),
          const SizedBox(width: 14),
          SizedBox(
            width: 110,
            child: Text(label,
                textAlign: TextAlign.start, style: ProfileTheme.label),
          ),
        ],
      ),
    );
  }
}

/// Avatar with a camera badge — picks an image, uploads it to Firebase
/// Storage, then persists the download URL on the user profile (US-36).
class _PhotoEdit extends StatefulWidget {
  const _PhotoEdit({required this.user});
  final AppUser user;

  @override
  State<_PhotoEdit> createState() => _PhotoEditState();
}

class _PhotoEditState extends State<_PhotoEdit> {
  Uint8List? _preview;
  bool _busy = false;

  Future<void> _pickAndUpload() async {
    if (_busy) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _preview = bytes;
        _busy = true;
      });

      final ref = FirebaseStorage.instance
          .ref('profile_photos/${widget.user.uid}.jpg');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      if (!mounted) return;

      // Persist the URL; _PersonalDataCard's listener refreshes the avatar
      // everywhere on success.
      context.read<ProfileBloc>().add(
            ProfileUpdateRequested(uid: widget.user.uid, photoUrl: url),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('تعذّر رفع الصورة: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.user.photoUrl;
    ImageProvider? image;
    if (_preview != null) {
      image = MemoryImage(_preview!);
    } else if (photoUrl != null) {
      image = NetworkImage(photoUrl);
    }
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: ProfileTheme.greenSoft,
              backgroundImage: image,
              child: image == null
                  ? const Icon(Icons.person, size: 42, color: ProfileTheme.green)
                  : null,
            ),
            if (_busy)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: ProfileTheme.green),
                  ),
                ),
              ),
            PositionedDirectional(
              bottom: 0,
              start: 0,
              child: GestureDetector(
                onTap: _pickAndUpload,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: ProfileTheme.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ----------------------------- personal data -----------------------------

class _PersonalDataCard extends StatefulWidget {
  const _PersonalDataCard({required this.user});
  final AppUser user;

  @override
  State<_PersonalDataCard> createState() => _PersonalDataCardState();
}

class _PersonalDataCardState extends State<_PersonalDataCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _email =
      TextEditingController(text: widget.user.email);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone ?? '');
  late final TextEditingController _city =
      TextEditingController(text: widget.user.city ?? '');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(ProfileUpdateRequested(
          uid: widget.user.uid,
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == UIStatus.error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state.status == UIStatus.success && state.user != null) {
          context.read<AuthBloc>().add(const AuthCheckRequested());
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات')));
        }
      },
      builder: (context, state) {
        final saving = state.status == UIStatus.loading;
        return ProfileCard(
          title: 'المعلومات الشخصية',
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _PhotoEdit(user: widget.user)),
                const SizedBox(height: 18),
                _FieldRow(
                  label: 'الاسم الكامل',
                  field: TextFormField(
                    controller: _name,
                    decoration: ProfileTheme.field('الاسم الكامل'),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'أدخل اسمًا صحيحًا'
                        : null,
                  ),
                ),
                _FieldRow(
                  label: 'البريد الإلكتروني',
                  field: TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: ProfileTheme.field('name@email.com'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'أدخل بريدًا صحيحًا'
                        : null,
                  ),
                ),
                _FieldRow(
                  label: 'رقم الجوال',
                  field: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: ProfileTheme.field('+966 5X XXX XXXX'),
                  ),
                ),
                _FieldRow(
                  label: 'المدينة',
                  field: TextFormField(
                    controller: _city,
                    decoration: ProfileTheme.field('المدينة'),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ProfileTheme.primaryButton,
                  onPressed: saving ? null : _save,
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ التغييرات'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------- password -----------------------------

class _PasswordCard extends StatefulWidget {
  const _PasswordCard();

  @override
  State<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<_PasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _ob1 = true, _ob2 = true, _ob3 = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  int _strength(String p) {
    if (p.isEmpty) return 0;
    if (p.length < 6) return 1;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s <= 1 ? 1 : (s == 2 ? 2 : 3);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthPasswordChangeRequested(
          currentPassword: _current.text,
          newPassword: _next.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == UIStatus.error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state.status == UIStatus.success) {
          _current.clear();
          _next.clear();
          _confirm.clear();
          setState(() {});
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
                const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')));
        }
      },
      builder: (context, state) {
        final saving = state.status == UIStatus.loading;
        final strength = _strength(_next.text);
        const labels = ['', 'ضعيفة', 'متوسطة', 'قوية'];
        const colors = [
          ProfileTheme.border,
          Color(0xFFEF4444),
          Color(0xFFF59E0B),
          ProfileTheme.green
        ];
        return ProfileCard(
          title: 'تغيير كلمة المرور',
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldRow(
                  label: 'كلمة المرور الحالية',
                  field: _pwField(_current, _ob1, () => setState(() => _ob1 = !_ob1),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'مطلوب' : null),
                ),
                _FieldRow(
                  label: 'كلمة المرور الجديدة',
                  field: _pwField(_next, _ob2, () => setState(() => _ob2 = !_ob2),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          (v == null || v.length < 6) ? '٦ أحرف على الأقل' : null),
                ),
                _FieldRow(
                  label: 'تأكيد كلمة المرور الجديدة',
                  field: _pwField(
                      _confirm, _ob3, () => setState(() => _ob3 = !_ob3),
                      validator: (v) =>
                          v != _next.text ? 'غير متطابقة' : null),
                ),
                if (_next.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Spacer(),
                    Text(labels[strength],
                        style: TextStyle(
                            color: colors[strength],
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(width: 6),
                    Text('قوة كلمة المرور:', style: ProfileTheme.hint),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (var i = 1; i <= 4; i++) ...[
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: strength * 4 ~/ 3 >= i
                                ? colors[strength]
                                : ProfileTheme.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      if (i < 4) const SizedBox(width: 6),
                    ],
                  ]),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ProfileTheme.primaryButton,
                  onPressed: saving ? null : _submit,
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('تحديث كلمة المرور'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pwField(
    TextEditingController c,
    bool obscure,
    VoidCallback toggle, {
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      decoration: ProfileTheme.field(
        '••••••••',
        prefix: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: ProfileTheme.muted, size: 20),
          onPressed: toggle,
        ),
      ),
    );
  }
}

// ----------------------------- notifications -----------------------------

class _NotificationsCard extends StatefulWidget {
  const _NotificationsCard();

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<_NotificationsCard> {
  final Map<String, bool> _values = {
    'إشعارات الرسائل': true,
    'إشعارات الاختبارات': true,
    'التقارير الأسبوعية': true,
    'التنبيهات المهمة': true,
  };

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'إعدادات الإشعارات',
      child: Column(
        children: [
          for (final entry in _values.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Switch(
                    value: entry.value,
                    activeThumbColor: ProfileTheme.green,
                    onChanged: (v) => setState(() => _values[entry.key] = v),
                  ),
                  const Spacer(),
                  Text(entry.key,
                      style: const TextStyle(
                          color: ProfileTheme.ink,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------- sessions -----------------------------

class _SessionsCard extends StatelessWidget {
  const _SessionsCard();

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'الجلسات والأمان',
      child: Column(
        children: [
          const InfoRow(label: 'الجهاز الحالي', value: 'Windows • الرياض'),
          const InfoRow(label: 'آخر تسجيل دخول', value: '٢٠ مايو ٢٠٢٤ - ٨:٤٥ م'),
          const InfoRow(
              label: 'تسجيلات الدخول', value: '١٢ جلسة هذا الشهر'),
          const SizedBox(height: 12),
          _OutlineButton(label: 'عرض جميع الجلسات', onTap: () {}),
        ],
      ),
    );
  }
}

// ----------------------------- devices -----------------------------

class _DevicesCard extends StatelessWidget {
  const _DevicesCard();

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'الأجهزة الموثوقة',
      child: Column(
        children: [
          const _DeviceRow(
              device: 'Windows • الرياض',
              date: '٢٠ مايو ٢٠٢٤',
              activeLabel: 'نشط الآن'),
          const _DeviceRow(device: 'iPhone • الرياض', date: '٢٠ مايو ٢٠٢٤'),
          const _DeviceRow(device: 'MacBook • الرياض', date: '١٨ مايو ٢٠٢٤'),
          const SizedBox(height: 12),
          _OutlineButton(label: 'إدارة الأجهزة', onTap: () {}),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow(
      {required this.device, required this.date, this.activeLabel});
  final String device;
  final String date;
  final String? activeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(date, style: ProfileTheme.hint.copyWith(fontSize: 12)),
          const Spacer(),
          if (activeLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: ProfileTheme.greenSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(activeLabel!,
                  style: const TextStyle(
                      color: ProfileTheme.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
            const SizedBox(width: 8),
          ],
          Text(device,
              style: const TextStyle(
                  color: ProfileTheme.ink, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: ProfileTheme.green,
          backgroundColor: ProfileTheme.bg,
          side: const BorderSide(color: ProfileTheme.border),
          minimumSize: const Size.fromHeight(44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
