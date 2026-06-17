// Smoke tests for Wesal. The full app needs Firebase + DI initialization,
// so here we test pure units (theme + domain) that don't require a backend.

import 'package:flutter_test/flutter_test.dart';
import 'package:maqraa/core/ui/styles/theme.dart';
import 'package:maqraa/domain/auth/models/app_user.dart';

void main() {
  test('official brand primary color is correct', () {
    expect(AppColors.primary.toARGB32(), 0xFF4E79A8);
  });

  test('UserRole maps to/from name', () {
    expect(UserRole.fromName('teacher'), UserRole.teacher);
    expect(UserRole.student.arabicLabel, 'طالبة');
  });

  test('Gender maps from name', () {
    expect(Gender.fromName('female'), Gender.female);
    expect(Gender.fromName('unknown'), isNull);
  });

  test('profile completeness requires role and gender', () {
    const incomplete = AppUser(uid: '1', name: 'أمل', email: 'a@b.com');
    final complete = incomplete.copyWith(role: UserRole.student, gender: Gender.female);
    expect(incomplete.hasCompletedProfile, isFalse);
    expect(complete.hasCompletedProfile, isTrue);
  });
}
