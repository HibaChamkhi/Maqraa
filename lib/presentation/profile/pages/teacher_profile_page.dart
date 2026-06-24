import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import 'profile_theme.dart';
import 'web_shell.dart';

/// Web teacher profile (الملف الشخصي): identity / account / circle info cards
/// and a centered KPI row, inside the green side-rail shell.
class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key, required this.user});

  final AppUser user;

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  late final Future<List<Circle>> _circles;
  Future<List<CircleMember>>? _members;

  @override
  void initState() {
    super.initState();
    _circles = getIt<CircleRepository>().getMyCircles();
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      user: widget.user,
      current: 'الإعدادات',
      breadcrumb: 'الإعدادات / الملف الشخصي',
      child: FutureBuilder<List<Circle>>(
        future: _circles,
        builder: (context, snap) {
          final circle =
              (snap.data ?? const []).isNotEmpty ? snap.data!.first : null;
          if (circle != null && _members == null) {
            _members = getIt<CircleRepository>().getMembers(circle.id);
          }
          final membersFuture =
              _members ?? Future.value(const <CircleMember>[]);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              LayoutBuilder(builder: (context, cc) {
                final cards = [
                  _CircleCard(circle: circle, members: membersFuture),
                  _AccountCard(user: widget.user),
                  _IdentityCard(user: widget.user),
                ];
                if (cc.maxWidth >= 820) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i < cards.length - 1) const SizedBox(width: 16),
                        ],
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final c in cards) ...[
                      c,
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 16),
              _StatsRow(members: membersFuture),
            ],
          );
        },
      ),
    );
  }
}

// --------------------------- info cards ---------------------------

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: ProfileTheme.cardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: ProfileTheme.sectionTitle, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'الملف الشخصي',
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: ProfileTheme.greenSoft,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, size: 44, color: ProfileTheme.green)
                : null,
          ),
          const SizedBox(height: 14),
          Text(user.name, style: ProfileTheme.name.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(user.role?.arabicLabel ?? '', style: ProfileTheme.hint),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: ProfileTheme.greenSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: ProfileTheme.green),
                SizedBox(width: 6),
                Text('معلم معتمد',
                    style: TextStyle(
                        color: ProfileTheme.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'معلومات الحساب',
      child: Column(
        children: [
          InfoRow(label: 'البريد الإلكتروني', value: user.email),
          InfoRow(label: 'رقم الجوال', value: user.phone ?? '—'),
          const InfoRow(label: 'اللغة', value: 'العربية'),
          const InfoRow(label: 'تاريخ الانضمام', value: '12 يناير 2023'),
          const InfoRow(label: 'آخر تسجيل دخول', value: '20 - مايو - 8:44 م'),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle, required this.members});
  final Circle? circle;
  final Future<List<CircleMember>> members;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'معلومات الحلقة',
      child: FutureBuilder<List<CircleMember>>(
        future: members,
        builder: (context, snap) {
          final count = snap.data
                  ?.where((m) => m.status == MemberStatus.active)
                  .length ??
              0;
          return Column(
            children: [
              InfoRow(label: 'اسم الحلقة', value: circle?.name ?? 'حلقة النور'),
              const InfoRow(label: 'المنطقة', value: 'مركز ورد القرآني'),
              const InfoRow(label: 'المدينة', value: 'الرياض'),
              InfoRow(
                  label: 'عدد الطلاب',
                  value: snap.connectionState == ConnectionState.waiting
                      ? '—'
                      : '$count طالب'),
              const InfoRow(label: 'المستوى', value: 'متوسط'),
            ],
          );
        },
      ),
    );
  }
}

/// Info row: label on the right, value on the left (RTL).
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ProfileTheme.hint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: ProfileTheme.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------- KPI row ---------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.members});
  final Future<List<CircleMember>> members;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CircleMember>>(
      future: members,
      builder: (context, snap) {
        final count = snap.data
                ?.where((m) => m.status == MemberStatus.active)
                .length ??
            0;
        final waiting = snap.connectionState == ConnectionState.waiting;
        final cards = <Widget>[
          StatCircle(
              icon: Icons.groups_outlined,
              value: waiting ? '—' : '$count',
              label: 'طالب',
              title: 'إجمالي الطلاب'),
          const StatCircle(
              icon: Icons.check_circle_outline,
              value: '92%',
              label: 'متوسط الحضور',
              title: 'الحضور هذا الشهر'),
          const StatCircle(
              icon: Icons.description_outlined,
              value: '24',
              label: 'اختبار',
              title: 'الاختبارات'),
          const StatCircle(
              icon: Icons.eco_outlined,
              value: '68%',
              label: 'هذا الشهر',
              title: 'متوسط التقدم'),
        ];
        return LayoutBuilder(builder: (context, c) {
          final perRow = c.maxWidth >= 720 ? 4 : 2;
          final width = (c.maxWidth - (perRow - 1) * 16) / perRow;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final card in cards) SizedBox(width: width, child: card),
            ],
          );
        });
      },
    );
  }
}

class StatCircle extends StatelessWidget {
  const StatCircle({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.title,
  });

  final IconData icon;
  final String value;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: ProfileTheme.cardShadow,
      child: Column(
        children: [
          Text(title, style: ProfileTheme.hint),
          const SizedBox(height: 14),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: ProfileTheme.greenSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ProfileTheme.green, size: 28),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: ProfileTheme.name.copyWith(fontSize: 26)),
          const SizedBox(height: 2),
          Text(label, style: ProfileTheme.hint),
        ],
      ),
    );
  }
}
