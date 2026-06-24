import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/model /ui_state.dart';
import '../bloc/auth_bloc.dart';
import '../pages/register_page.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  static const Color _green = Color(0xFF2E7D52);
  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF7C8A86);

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _identifierController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle:
            GoogleFonts.tajawal(color: _muted, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE9E4DA)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE9E4DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthBloc, bool>(
      (b) => b.state.status == UIStatus.loading,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'مرحباً بك مجدداً',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'سجّل الدخول لمتابعة رحلتك',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _field('البريد الإلكتروني أو رقم الجوال'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'أدخل بريدك أو رقم جوالك'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  onFieldSubmitted: (_) => _onLogin(),
                  decoration: _field('كلمة المرور').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: _muted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'كلمة المرور قصيرة' : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _green,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: GoogleFonts.tajawal(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                          content:
                              Text('سيتم تفعيل استعادة كلمة المرور قريبًا'),
                        ));
                    },
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),
                const SizedBox(height: 20),
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
                    onPressed: loading ? null : _onLogin,
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('تسجيل الدخول'),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟ ',
                      style: GoogleFonts.tajawal(
                          color: _muted, fontWeight: FontWeight.w500),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ),
                      child: Text(
                        'إنشاء حساب',
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
    );
  }
}
