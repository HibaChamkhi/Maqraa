import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_page.dart';
import 'register_page.dart';

/// First screen for signed-out users: brand intro with the Quran illustration
/// and the two entry actions (create account / sign in).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // Deep forest green used for the primary actions in the auth flow.
  static const Color _green = Color(0xFF2E7D52);
  static const Color _cream = Color(0xFFF6F1E8);
  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF7C8A86);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                'رحلة حفظ القرآن\nتبدأ بخطوة',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'نظّم وقتك، تابع تقدّمك،\nواحفظ مع رفيقك بإذن الله.',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
              const Spacer(),
              const _Illustration(),
              const SizedBox(height: 28),
              const _Dots(count: 5, active: 0, color: _green),
              const Spacer(),
              SizedBox(
                width: double.infinity,
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text('إنشاء حساب'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE3DED3)),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.tajawal(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('تسجيل الدخول'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quran-on-rehal illustration inside a soft green circle.
/// Drop the artwork at assets/images/onboarding_quran.png; until then a
/// simple vector fallback is shown.
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE3EDE2),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/onboarding_quran.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => const Center(
          child: Icon(Icons.menu_book_rounded,
              size: 96, color: Color(0xFF2E7D52)),
        ),
      ),
    );
  }
}

/// Page indicator dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active, required this.color});

  final int count;
  final int active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? color : const Color(0xFFCFD6CF),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}
