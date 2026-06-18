import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import 'profile_theme.dart';

/// تعديل المعلومات الشخصية — edit name / email / phone (saved) plus
/// city + stage (shown to match the design, not persisted yet).
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final _city = TextEditingController();

  static const _stages = [
    'المرحلة الابتدائية',
    'المرحلة المتوسطة',
    'المرحلة الثانوية',
    'جامعي',
    'أخرى',
  ];
  String? _stage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  void _save(AppUser user) {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            uid: user.uid,
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      body: BlocConsumer<ProfileBloc, ProfileState>(
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
              ..showSnackBar(
                  const SnackBar(content: Text('تم حفظ التعديلات بنجاح')));
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          final saving = state.status == UIStatus.loading;
          return SafeArea(
            child: Column(
              children: [
                _Header(title: 'تعديل المعلومات الشخصية'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Center(child: _PhotoPicker(user: user)),
                            const SizedBox(height: 24),
                            _label('الاسم الكامل'),
                            TextFormField(
                              controller: _name,
                              decoration: ProfileTheme.field('الاسم الكامل'),
                              validator: (v) =>
                                  (v == null || v.trim().length < 3)
                                      ? 'أدخل اسمًا صحيحًا'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            _label('البريد الإلكتروني'),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration:
                                  ProfileTheme.field('name@email.com'),
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'أدخل بريدًا صحيحًا'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _label('رقم الجوال'),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration:
                                  ProfileTheme.field('+966 5X XXX XXXX'),
                            ),
                            const SizedBox(height: 16),
                            _label('المدينة'),
                            TextFormField(
                              controller: _city,
                              decoration: ProfileTheme.field('المدينة'),
                            ),
                            const SizedBox(height: 16),
                            _label('المرحلة'),
                            DropdownButtonFormField<String>(
                              initialValue: _stage,
                              isExpanded: true,
                              decoration: ProfileTheme.field('اختر المرحلة'),
                              items: [
                                for (final s in _stages)
                                  DropdownMenuItem(value: s, child: Text(s)),
                              ],
                              onChanged: (v) => setState(() => _stage = v),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              style: ProfileTheme.primaryButton,
                              onPressed: saving ? null : () => _save(user),
                              child: saving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text('حفظ التغييرات'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 2),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(text, style: ProfileTheme.label),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: ProfileTheme.appBarTitle),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: ProfileTheme.ink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('صورة الملف الشخصي', style: ProfileTheme.hint),
        const SizedBox(height: 12),
        Stack(
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: ProfileTheme.greenSoft,
              backgroundImage:
                  user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? const Icon(Icons.person,
                      size: 46, color: ProfileTheme.green)
                  : null,
            ),
            PositionedDirectional(
              bottom: 0,
              start: 0,
              child: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                      content: Text('سيتم تفعيل تغيير الصورة قريبًا'))),
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
