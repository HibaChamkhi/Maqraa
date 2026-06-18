import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/model /ui_state.dart';
import '../../../domain/auth/models/app_user.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color _green = Color(0xFF2E7D52);
  static const Color _cream = Color(0xFFF6F1E8);
  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF7C8A86);
  static const Color _fieldBorder = Color(0xFFE9E4DA);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  Gender? _gender;
  UserRole? _role;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _toast('يرجى اختيار الجنس');
      return;
    }
    if (_role == null) {
      _toast('يرجى اختيار نوع الحساب');
      return;
    }
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            gender: _gender!,
            role: _role,
          ),
        );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _field(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle:
            GoogleFonts.tajawal(color: _muted, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == UIStatus.error) {
            _toast(state.message);
          } else if (state.status == UIStatus.success && state.user != null) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
        builder: (context, state) {
          final loading = state.status == UIStatus.loading;
          return SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: _ink, size: 30),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'أنشئ حسابك',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'ابدأ رحلتك في حفظ القرآن الكريم',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.tajawal(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _name,
                              decoration: _field('الاسم الكامل'),
                              validator: (v) =>
                                  (v == null || v.trim().length < 3)
                                      ? 'أدخل اسمًا صحيحًا'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _field('البريد الإلكتروني'),
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? 'أدخل بريدًا صحيحًا'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: _field('رقم الجوال (اختياري)'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: _field(
                                'كلمة المرور',
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: _muted,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? '٦ أحرف على الأقل'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            _label('الجنس'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _PillChoice(
                                    label: 'أنثى',
                                    selected: _gender == Gender.female,
                                    onTap: () => setState(
                                        () => _gender = Gender.female),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PillChoice(
                                    label: 'ذكر',
                                    selected: _gender == Gender.male,
                                    onTap: () =>
                                        setState(() => _gender = Gender.male),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _label('نوع الحساب'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final role in UserRole.values)
                                  _PillChoice(
                                    label: role.arabicLabel,
                                    selected: _role == role,
                                    onTap: () => setState(() => _role = role),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: GoogleFonts.tajawal(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                onPressed: loading ? null : _submit,
                                child: loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text('إنشاء الحساب'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'لديك حساب؟ ',
                                  style: GoogleFonts.tajawal(
                                      color: _muted,
                                      fontWeight: FontWeight.w500),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).maybePop(),
                                  child: Text(
                                    'تسجيل الدخول',
                                    style: GoogleFonts.tajawal(
                                      color: _green,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _label(String text) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      );
}

/// White / green selectable pill used for gender + role choices.
class _PillChoice extends StatelessWidget {
  const _PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _green = Color(0xFF2E7D52);
  static const Color _muted = Color(0xFF7C8A86);
  static const Color _border = Color(0xFFE9E4DA);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _green : _border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _muted,
          ),
        ),
      ),
    );
  }
}
