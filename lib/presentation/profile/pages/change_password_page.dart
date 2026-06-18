import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/model /ui_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'profile_theme.dart';

/// تغيير كلمة المرور — current / new / confirm with a live strength meter.
/// Wired to [AuthPasswordChangeRequested].
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obCurrent = true, _obNext = true, _obConfirm = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthPasswordChangeRequested(
            currentPassword: _current.text,
            newPassword: _next.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == UIStatus.error) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state.status == UIStatus.success) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                  content: Text('تم تغيير كلمة المرور بنجاح')));
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          final saving = state.status == UIStatus.loading;
          final strength = _strength(_next.text);
          return SafeArea(
            child: Column(
              children: [
                _Header(title: 'تغيير كلمة المرور'),
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
                            _label('كلمة المرور الحالية'),
                            _PasswordField(
                              controller: _current,
                              obscure: _obCurrent,
                              onToggle: () =>
                                  setState(() => _obCurrent = !_obCurrent),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            _label('كلمة المرور الجديدة'),
                            _PasswordField(
                              controller: _next,
                              obscure: _obNext,
                              onToggle: () =>
                                  setState(() => _obNext = !_obNext),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => (v == null || v.length < 6)
                                  ? '٦ أحرف على الأقل'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            _label('تأكيد كلمة المرور الجديدة'),
                            _PasswordField(
                              controller: _confirm,
                              obscure: _obConfirm,
                              onToggle: () =>
                                  setState(() => _obConfirm = !_obConfirm),
                              validator: (v) => v != _next.text
                                  ? 'كلمتا المرور غير متطابقتين'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            if (_next.text.isNotEmpty) ...[
                              _StrengthMeter(strength: strength),
                              const SizedBox(height: 28),
                            ] else
                              const SizedBox(height: 28),
                            ElevatedButton(
                              style: ProfileTheme.primaryButton,
                              onPressed: saving ? null : _submit,
                              child: saving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text('تحديث كلمة المرور'),
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

/// 0 = none, 1 = weak, 2 = medium, 3 = strong.
int _strength(String p) {
  if (p.isEmpty) return 0;
  var score = 0;
  if (p.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
  if (RegExp(r'[0-9]').hasMatch(p)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
  if (p.length < 6) return 1;
  return score <= 1 ? 1 : (score == 2 ? 2 : 3);
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    const labels = ['', 'ضعيفة', 'متوسطة', 'قوية'];
    const colors = [
      ProfileTheme.border,
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      ProfileTheme.green,
    ];
    final color = colors[strength];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('قوة كلمة المرور: ', style: ProfileTheme.hint),
            Text(labels[strength],
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 3; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: strength >= i ? color : ProfileTheme.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      decoration: ProfileTheme.field(
        '••••••••',
        suffix: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: ProfileTheme.muted, size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }
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
