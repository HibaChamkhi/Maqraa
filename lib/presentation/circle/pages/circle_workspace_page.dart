import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import '../../../core/data/quran_surahs.dart';
import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/util/last_location_store.dart';
import '../../../core/util/notify.dart';
import '../../../core/util/session_occurrences.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/homework/models/weekly_homework.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../../calendar/bloc/calendar_bloc.dart';
import '../../exam/pages/teacher_exams_page.dart';
import '../../exam/pages/student_exams_page.dart';
import '../../homework/pages/weekly_homework_tab.dart';
import '../../session/pages/live_session_page.dart';
import '../bloc/circle_bloc.dart';

Color attendanceColor(AttendanceState? a) {
  switch (a) {
    case AttendanceState.present:
      return AppColors.success;
    case AttendanceState.excused:
      return AppColors.warning;
    case AttendanceState.absent:
      return AppColors.error;
    case AttendanceState.late_:
      return AppColors.textMuted;
    case null:
      return AppColors.textMuted;
  }
}

Color performanceColor(PerformanceTag? p) {
  switch (p) {
    case PerformanceTag.excellent:
      return AppColors.success;
    case PerformanceTag.good:
      return AppColors.primaryLight;
    case PerformanceTag.average:
      return AppColors.warning;
    case PerformanceTag.needsFollowUp:
      return AppColors.error;
    case null:
      return AppColors.textMuted;
  }
}

/// The workspace of ONE حلقة. Everything here is scoped to [circle].
class CircleWorkspacePage extends StatefulWidget {
  final Circle circle;
  final AppUser user;
  final int initialTab;

  const CircleWorkspacePage(
      {super.key,
      required this.circle,
      required this.user,
      this.initialTab = 0});

  @override
  State<CircleWorkspacePage> createState() => _CircleWorkspacePageState();
}

class _CircleWorkspacePageState extends State<CircleWorkspacePage> {
  // Authority is scoped to THIS circle, not the global account role.
  bool get _canManage => widget.circle.canManage(widget.user);

  late Circle _circle = widget.circle;

  @override
  void initState() {
    super.initState();
    // Remember this circle + tab so a web refresh restores it.
    LastLocationStore.saveCircle(widget.circle.id, widget.initialTab);
  }

  @override
  void dispose() {
    // Leaving the workspace (back) clears the saved location.
    LastLocationStore.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circle = _circle;
    final user = widget.user;
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 48, title: const SizedBox.shrink()),
        // NestedScrollView: the info header scrolls away while the tab bar
        // stays pinned, so the tab body always has full height (no overflow).
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: _CircleHeader(
                circle: circle,
                user: user,
                canManage: _canManage,
                onEdited: (c) => setState(() => _circle = c),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeader(
                TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  tabAlignment: TabAlignment.start,
                  onTap: (i) => LastLocationStore.saveCircle(circle.id, i),
                  tabs: const [
                    Tab(text: 'الطالبات'),
                    Tab(text: 'الجدول'),
                    Tab(text: 'الجلسات'),
                    Tab(text: 'الاختبارات'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _StudentsTab(circle: circle, canManage: _canManage),
              // الجدول = weekly homework (الواجب الأسبوعي)
              WeeklyHomeworkTab(
                  circle: circle, user: user, canManage: _canManage),
              // الجلسات = the session-times manager (moved here)
              _ScheduleTab(
                  circle: circle,
                  user: user,
                  canManage: _canManage,
                  onCircleChanged: (c) => setState(() => _circle = c)),
              // الاختبارات = exams list inline (managers grade, students view)
              _canManage
                  ? TeacherExamsPage(
                      circleId: circle.id, user: user, embedded: true)
                  : StudentExamsPage(
                      circleId: circle.id, user: user, embedded: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinned tab bar for the NestedScrollView header (keeps the tabs visible
/// while the info header scrolls away).
class _TabBarHeader extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarHeader(this.tabBar);

  static const double _height = 49;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tabBar,
          const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

// ---------------------------------------------------------------------------
//  Hero header (breadcrumb + title + count + info cards + invite code)
// ---------------------------------------------------------------------------

class _CircleHeader extends StatelessWidget {
  final Circle circle;
  final AppUser user;
  final bool canManage;
  final ValueChanged<Circle>? onEdited;
  const _CircleHeader(
      {required this.circle,
      required this.user,
      required this.canManage,
      this.onEdited});

  /// The owning teacher's name — falls back to the current owner's name when
  /// the stored teacherName is empty (legacy circles).
  String get _teacherName {
    if (circle.teacherName.isNotEmpty) return circle.teacherName;
    if (user.uid == circle.teacherId && user.name.isNotEmpty) return user.name;
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('الحلقات / ${circle.name}',
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(circle.name,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (canManage) ...[
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'تعديل الحلقة',
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: AppColors.primary),
                onPressed: () async {
                  final updated = await showDialog<Circle>(
                    context: context,
                    builder: (_) => _EditCircleDialog(circle: circle),
                  );
                  if (updated != null) onEdited?.call(updated);
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        _DescriptionLine(circle: circle, canManage: canManage),
        const SizedBox(height: 2),
        _MemberCount(circleId: circle.id),
      ],
    );

    final cards = <Widget>[
      _InfoCard(
          icon: Icons.person_outline,
          label: 'المعلم المسؤول',
          value: _teacherName),
      _DaysInfoCard(circle: circle, canManage: canManage),
      _LevelInfoCard(circle: circle, canManage: canManage),
      _RiwayahInfoCard(circle: circle, canManage: canManage),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      color: AppColors.background,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 760;
        final invite = canManage ? _InviteCard(code: circle.inviteCode) : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerRight, child: titleBlock),
            const SizedBox(height: AppSpacing.md),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(child: cards[i]),
                    ],
                    if (invite != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(width: 260, child: invite),
                    ],
                  ],
                ),
              )
            else ...[
              for (final card in cards) ...[
                card,
                const SizedBox(height: AppSpacing.sm),
              ],
              if (invite != null) invite,
            ],
          ],
        );
      }),
    );
  }
}

/// Owner-only "تعديل الحلقة" popup — fix the title and toggle privacy.
/// (نبذة / المستوى / الرواية stay editable on their own header cards.)
class _EditCircleDialog extends StatefulWidget {
  final Circle circle;
  const _EditCircleDialog({required this.circle});

  @override
  State<_EditCircleDialog> createState() => _EditCircleDialogState();
}

class _EditCircleDialogState extends State<_EditCircleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.circle.name);
  late Privacy _privacy = widget.circle.privacy;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    final repo = getIt<CircleRepository>();
    final newName = _name.text.trim();
    try {
      if (newName != widget.circle.name) {
        await repo.updateName(circleId: widget.circle.id, name: newName);
      }
      if (_privacy != widget.circle.privacy) {
        await repo.updatePrivacy(circleId: widget.circle.id, privacy: _privacy);
      }
      if (mounted) {
        Navigator.of(context)
            .pop(widget.circle.copyWith(name: newName, privacy: _privacy));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('تعذّر حفظ التعديلات — تحقّقي من الاتصال/الصلاحيات')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0),
      title: Row(
        children: [
          const Expanded(child: Text('تعديل الحلقة')),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'إلغاء',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم الحلقة',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'يرجى إدخال اسم الحلقة'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('الخصوصية',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 6),
              SegmentedButton<Privacy>(
                segments: const [
                  ButtonSegment(
                      value: Privacy.private,
                      label: Text('خاصة'),
                      icon: Icon(Icons.lock_outline)),
                  ButtonSegment(
                      value: Privacy.public,
                      label: Text('عامة'),
                      icon: Icon(Icons.public)),
                ],
                selected: {_privacy},
                onSelectionChanged: (s) => setState(() => _privacy = s.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCount extends StatelessWidget {
  final String circleId;
  const _MemberCount({required this.circleId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getIt<CircleRepository>().getMembers(circleId),
      builder: (context, snap) {
        final n = (snap.data ?? const [])
            .where((m) =>
                m.role == UserRole.student && m.status == MemberStatus.active)
            .length;
        return Text('عدد الطالبات: $n',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted));
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A1F2937), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Teacher-written short note under the circle name (editable by the teacher).
class _DescriptionLine extends StatefulWidget {
  final Circle circle;
  final bool canManage;
  const _DescriptionLine({required this.circle, required this.canManage});

  @override
  State<_DescriptionLine> createState() => _DescriptionLineState();
}

class _DescriptionLineState extends State<_DescriptionLine> {
  late String _desc = widget.circle.description;

  Future<void> _edit() async {
    final c = TextEditingController(text: _desc);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نبذة الحلقة'),
        content: SizedBox(
          width: 340,
          child: TextField(
            controller: c,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'وصف مختصر للحلقة (اختياري)'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _desc = c.text.trim());
    await getIt<CircleRepository>()
        .updateDescription(circleId: widget.circle.id, description: c.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _desc.isEmpty
        ? (widget.canManage ? 'أضيفي نبذة عن الحلقة' : '')
        : _desc;
    if (text.isEmpty) return const SizedBox.shrink();
    final label = Flexible(
      child: Text(text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
              color: _desc.isEmpty ? AppColors.textMuted : AppColors.ink)),
    );
    if (!widget.canManage) {
      return Row(mainAxisSize: MainAxisSize.min, children: [label]);
    }
    return InkWell(
      onTap: _edit,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        label,
        const SizedBox(width: 4),
        const Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
      ]),
    );
  }
}

/// «أيام الحلقة» card — derives the meeting days from the circle's actual
/// sessions (their distinct weekdays), since scheduling is session-based.
class _DaysInfoCard extends StatelessWidget {
  final Circle circle;
  final bool canManage;
  const _DaysInfoCard({required this.circle, required this.canManage});

  // Tapping jumps to the الجلسات tab where the fixed schedule is edited.
  Widget _wrap(BuildContext context, Widget card) {
    if (!canManage) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => DefaultTabController.maybeOf(context)?.animateTo(2),
      child: card,
    );
  }

  Widget _card(String value) => _InfoCard(
        icon: Icons.event_outlined,
        label: 'أيام الحلقة',
        value: value,
      );

  @override
  Widget build(BuildContext context) {
    // Prefer the fixed rule (single source of truth); fall back to deriving
    // days from sessions for circles that haven't set a rule yet.
    if (circle.days.isNotEmpty) {
      final days = [
        for (final code in _scheduleDayOrder)
          if (circle.days.contains(code)) _scheduleDayLabels[code]!
      ];
      return _wrap(context, _card(days.isEmpty ? 'لم تُحدَّد' : days.join(' · ')));
    }
    return FutureBuilder<List<Session>>(
      future: getIt<CalendarRepository>().getSessions(circle.id),
      builder: (context, snap) {
        final sessions = snap.data ?? const <Session>[];
        final wds = sessions.map((s) => s.scheduledAt.weekday).toSet();
        final days = [
          for (final code in _scheduleDayOrder)
            if (wds.contains(_codeToWeekday[code])) _scheduleDayLabels[code]!
        ];
        return _wrap(
            context, _card(days.isEmpty ? 'لم تُحدَّد' : days.join(' · ')));
      },
    );
  }
}

/// «مستوى الحلقة» card — surah + ayah range, editable by the teacher.
class _LevelInfoCard extends StatefulWidget {
  final Circle circle;
  final bool canManage;
  const _LevelInfoCard({required this.circle, required this.canManage});

  @override
  State<_LevelInfoCard> createState() => _LevelInfoCardState();
}

class _LevelInfoCardState extends State<_LevelInfoCard> {
  late String _unit = widget.circle.levelUnit;
  late SurahInfo? _surah = _findSurah(widget.circle.levelSurah);
  late int? _from = widget.circle.levelFromAyah;
  late int? _to = widget.circle.levelToAyah;

  static SurahInfo? _findSurah(String name) {
    for (final s in kSurahs) {
      if (s.name == name) return s;
    }
    return null;
  }

  String get _label {
    final f = _from, t = _to;
    String pair(String u) => (t == null || t == f) ? '$u $f' : '$u $f – $t';
    switch (_unit) {
      case 'juz':
        return f == null ? 'لم يُحدَّد' : pair('جزء');
      case 'hizb':
        return f == null ? 'لم يُحدَّد' : pair('حزب');
      case 'surah':
        if (_surah == null) return 'لم يُحدَّد';
        if (f == null) return _surah!.name;
        return (t == null || t == f)
            ? '${_surah!.name} · الآية $f'
            : '${_surah!.name} · الآيات $f–$t';
      default:
        return 'لم يُحدَّد';
    }
  }

  Future<void> _edit() async {
    final result = await showDialog<
        ({String unit, SurahInfo? surah, int? from, int? to})>(
      context: context,
      builder: (_) => _LevelEditorDialog(
        initialUnit: _unit.isEmpty ? 'juz' : _unit,
        initialSurah: _surah,
        initialFrom: _from,
        initialTo: _to,
      ),
    );
    if (result == null) return;
    setState(() {
      _unit = result.unit;
      _surah = result.surah;
      _from = result.from;
      _to = result.to;
    });
    try {
      await getIt<CircleRepository>().updateLevel(
        circleId: widget.circle.id,
        unit: result.unit,
        surah: result.surah?.name ?? '',
        fromAyah: result.from,
        toAyah: result.to,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث مستوى الحلقة')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّر الحفظ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _InfoCard(
        icon: Icons.menu_book_outlined, label: 'مستوى الحلقة', value: _label);
    if (!widget.canManage) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: _edit,
      child: card,
    );
  }
}

class _LevelEditorDialog extends StatefulWidget {
  final String initialUnit;
  final SurahInfo? initialSurah;
  final int? initialFrom;
  final int? initialTo;
  const _LevelEditorDialog(
      {required this.initialUnit,
      this.initialSurah,
      this.initialFrom,
      this.initialTo});

  @override
  State<_LevelEditorDialog> createState() => _LevelEditorDialogState();
}

class _LevelEditorDialogState extends State<_LevelEditorDialog> {
  late String _unit = widget.initialUnit;
  late int? _surahNum = widget.initialSurah?.number;
  // ayah range (surah unit)
  late final TextEditingController _ayahFrom = TextEditingController(
      text: widget.initialUnit == 'surah'
          ? (widget.initialFrom?.toString() ?? '')
          : '');
  late final TextEditingController _ayahTo = TextEditingController(
      text: widget.initialUnit == 'surah'
          ? (widget.initialTo?.toString() ?? '')
          : '');
  // numeric range (juz/hizb unit)
  late int? _numFrom = widget.initialUnit == 'surah' ? null : widget.initialFrom;
  late int? _numTo = widget.initialUnit == 'surah' ? null : widget.initialTo;

  int get _maxUnit => _unit == 'hizb' ? 60 : 30;

  @override
  void dispose() {
    _ayahFrom.dispose();
    _ayahTo.dispose();
    super.dispose();
  }

  void _save() {
    if (_unit == 'surah') {
      if (_surahNum == null) {
        Navigator.of(context)
            .pop((unit: 'surah', surah: null, from: null, to: null));
        return;
      }
      final surah = kSurahs[_surahNum! - 1];
      int? from = int.tryParse(_ayahFrom.text.trim());
      int? to = int.tryParse(_ayahTo.text.trim());
      if (from != null) from = from.clamp(1, surah.ayahs).toInt();
      if (to != null) to = to.clamp(1, surah.ayahs).toInt();
      if (from != null && to != null && from > to) {
        final tmp = from;
        from = to;
        to = tmp;
      }
      Navigator.of(context)
          .pop((unit: 'surah', surah: surah, from: from, to: to));
    } else {
      var from = _numFrom, to = _numTo;
      if (from != null && to != null && from > to) {
        final tmp = from;
        from = to;
        to = tmp;
      }
      Navigator.of(context)
          .pop((unit: _unit, surah: null, from: from, to: to));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('مستوى الحلقة'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'juz', label: Text('جزء')),
                ButtonSegment(value: 'hizb', label: Text('حزب')),
                ButtonSegment(value: 'surah', label: Text('سورة')),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() {
                _unit = s.first;
                if (_unit != 'surah') {
                  if (_numFrom != null && _numFrom! > _maxUnit) _numFrom = null;
                  if (_numTo != null && _numTo! > _maxUnit) _numTo = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            if (_unit == 'surah') ...[
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: _surahNum,
                decoration:
                    const InputDecoration(labelText: 'السورة', isDense: true),
                items: [
                  for (final s in kSurahs)
                    DropdownMenuItem(
                        value: s.number,
                        child: Text('${s.number}. ${s.name}')),
                ],
                onChanged: (v) => setState(() => _surahNum = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ayahFrom,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'من آية',
                        isDense: true,
                        helperText: _surahNum == null
                            ? null
                            : '1–${kSurahs[_surahNum! - 1].ayahs}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ayahTo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'إلى آية', isDense: true),
                  ),
                ),
              ]),
            ] else ...[
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _numFrom,
                    decoration: const InputDecoration(
                        labelText: 'من', isDense: true),
                    items: [
                      for (var i = 1; i <= _maxUnit; i++)
                        DropdownMenuItem(value: i, child: Text('$i')),
                    ],
                    onChanged: (v) => setState(() => _numFrom = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _numTo,
                    decoration: const InputDecoration(
                        labelText: 'إلى', isDense: true),
                    items: [
                      for (var i = 1; i <= _maxUnit; i++)
                        DropdownMenuItem(value: i, child: Text('$i')),
                    ],
                    onChanged: (v) => setState(() => _numTo = v),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء')),
        ElevatedButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}

/// «رواية الحلقة» card — pick from the common روايات, editable by the teacher.
class _RiwayahInfoCard extends StatefulWidget {
  final Circle circle;
  final bool canManage;
  const _RiwayahInfoCard({required this.circle, required this.canManage});

  @override
  State<_RiwayahInfoCard> createState() => _RiwayahInfoCardState();
}

class _RiwayahInfoCardState extends State<_RiwayahInfoCard> {
  late String _riwayah = widget.circle.riwayah;

  Future<void> _edit() async {
    var selected = _riwayah.isEmpty ? kRiwayat.first : _riwayah;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رواية الحلقة'),
        content: SizedBox(
          width: 320,
          child: StatefulBuilder(
            builder: (ctx, setLocal) => DropdownButtonFormField<String>(
              isExpanded: true,
              value: selected,
              decoration:
                  const InputDecoration(labelText: 'الرواية', isDense: true),
              items: [
                for (final r in kRiwayat)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setLocal(() => selected = v ?? selected),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (result == null) return;
    setState(() => _riwayah = result);
    try {
      await getIt<CircleRepository>()
          .updateRiwayah(circleId: widget.circle.id, riwayah: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث رواية الحلقة')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّر الحفظ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _InfoCard(
        icon: Icons.record_voice_over_outlined,
        label: 'رواية الحلقة',
        value: _riwayah.isEmpty ? 'لم تُحدَّد' : _riwayah);
    if (!widget.canManage) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: _edit,
      child: card,
    );
  }
}

class _InviteCard extends StatelessWidget {
  final String code;
  const _InviteCard({required this.code});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void copy() {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ رمز الدعوة')));
    }

    Future<void> share() async {
      try {
        await Share.share(
          'انضمي إلى حلقتنا في تطبيق «وِصَال» باستخدام رمز الدعوة: $code',
          subject: 'دعوة للانضمام إلى حلقة في وِصَال',
        );
      } catch (_) {
        // Web desktop often has no share support — fall back to copy.
        await Clipboard.setData(ClipboardData(text: code));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم نسخ رمز الدعوة للمشاركة')));
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('رمز الدعوة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(code,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.primaryDark)),
                InkWell(
                  onTap: copy,
                  child: const Icon(Icons.copy_outlined,
                      size: 18, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: share,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('مشاركة الدعوة'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  الجدول tab — recurring weekly meeting schedule (days + per-day time)
// ---------------------------------------------------------------------------

const _scheduleDayOrder = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];
const _scheduleDayLabels = {
  'sat': 'السبت',
  'sun': 'الأحد',
  'mon': 'الإثنين',
  'tue': 'الثلاثاء',
  'wed': 'الأربعاء',
  'thu': 'الخميس',
  'fri': 'الجمعة',
};

const _codeToWeekday = {
  'sat': DateTime.saturday,
  'sun': DateTime.sunday,
  'mon': DateTime.monday,
  'tue': DateTime.tuesday,
  'wed': DateTime.wednesday,
  'thu': DateTime.thursday,
  'fri': DateTime.friday,
};

Color _sessionTypeColor(SessionType t) =>
    t == SessionType.imla2 ? AppColors.warning : AppColors.primary;

/// الجدول tab — manage this circle's sessions (single or recurring),
/// each independently editable/cancelable.
class _ScheduleTab extends StatelessWidget {
  final Circle circle;
  final AppUser user;
  final bool canManage;
  final ValueChanged<Circle>? onCircleChanged;
  const _ScheduleTab(
      {required this.circle,
      required this.user,
      required this.canManage,
      this.onCircleChanged});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CalendarBloc>()..add(CalendarSessionsRequested(circle.id)),
      child: _ScheduleView(
          circle: circle,
          user: user,
          canManage: canManage,
          onCircleChanged: onCircleChanged),
    );
  }
}

class _ScheduleView extends StatelessWidget {
  final Circle circle;
  final AppUser user;
  final bool canManage;
  final ValueChanged<Circle>? onCircleChanged;
  const _ScheduleView(
      {required this.circle,
      required this.user,
      required this.canManage,
      this.onCircleChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerFmt = DateFormat('EEEE d MMMM', 'ar');
    return BlocConsumer<CalendarBloc, CalendarState>(
      listenWhen: (p, c) => c.message.isNotEmpty && p.message != c.message,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.message)));
      },
      builder: (context, state) {
        if (state.status == UIStatus.loading && state.sessions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final upcoming = state.sessions
            .where((s) => !s.scheduledAt.isBefore(start))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

        // group by day
        final groups = <String, List<Session>>{};
        for (final s in upcoming) {
          final key = DateFormat('yyyy-MM-dd').format(s.scheduledAt);
          (groups[key] ??= []).add(s);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  if (canManage)
                    ElevatedButton.icon(
                      onPressed: () => _openForm(context, circle.id),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('جلسة جديدة'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44)),
                    ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => LiveSessionPage(
                                circleId: circle.id, user: user))),
                    icon: const Icon(Icons.podcasts_outlined, size: 18),
                    label: const Text('الجلسة المباشرة'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44)),
                  ),
                ],
              ),
            ),
            if (canManage || circle.days.isNotEmpty)
              _FixedScheduleCard(
                  circle: circle,
                  canManage: canManage,
                  onChanged: onCircleChanged),
            Expanded(
              child: circle.days.isNotEmpty
                  ? _GeneratedSchedule(
                      circle: circle,
                      user: user,
                      canManage: canManage,
                      onAddExtra: canManage
                          ? () => _openForm(context, circle.id)
                          : null,
                    )
                  : upcoming.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_available_outlined,
                                size: 56, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('لا توجد جلسات قادمة',
                                style: theme.textTheme.titleMedium),
                            if (canManage) ...[
                              const SizedBox(height: 6),
                              Text('أضيفي جلسة من زر «جلسة جديدة».',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMuted)),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                      children: [
                        for (final entry in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                            child: Text(
                                headerFmt
                                    .format(entry.value.first.scheduledAt),
                                style: theme.textTheme.titleSmall),
                          ),
                          for (final s in entry.value)
                            _SessionCard(
                              session: s,
                              canManage: canManage,
                              onEdit: () =>
                                  _openForm(context, circle.id, initial: s),
                              onDelete: () =>
                                  _confirmDelete(context, circle.id, s),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  void _openForm(BuildContext context, String circleId, {Session? initial}) {
    final bloc = context.read<CalendarBloc>();
    showDialog<void>(
      context: context,
      builder: (_) =>
          _SessionForm(bloc: bloc, circleId: circleId, initial: initial),
    );
  }

  void _confirmDelete(BuildContext context, String circleId, Session s) {
    final bloc = context.read<CalendarBloc>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الجلسة'),
        content: Text(s.isRecurring
            ? 'هذه الجلسة ضمن سلسلة متكرّرة. ماذا تريدين حذفه؟'
            : 'هل تريدين حذف هذه الجلسة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          if (s.isRecurring)
            TextButton(
              onPressed: () {
                bloc.add(CalendarSeriesDeleted(
                    circleId: circleId, recurrenceId: s.recurrenceId!));
                Navigator.pop(ctx);
              },
              child: const Text('حذف السلسلة كاملة'),
            ),
          ElevatedButton(
            onPressed: () {
              bloc.add(
                  CalendarSessionDeleted(circleId: circleId, sessionId: s.id));
              Navigator.pop(ctx);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.isRecurring ? 'حذف هذه فقط' : 'حذف'),
          ),
        ],
      ),
    );
  }
}

/// «الجدول الثابت» — the حلقة's fixed recurring rule (days + time + duration),
/// the single source of truth for أيام الحلقة and the attendance columns.
class _FixedScheduleCard extends StatefulWidget {
  final Circle circle;
  final bool canManage;
  final ValueChanged<Circle>? onChanged;
  const _FixedScheduleCard(
      {required this.circle, required this.canManage, this.onChanged});

  @override
  State<_FixedScheduleCard> createState() => _FixedScheduleCardState();
}

class _FixedScheduleCardState extends State<_FixedScheduleCard> {
  late Map<String, String> _dayTimes =
      Map<String, String>.from(widget.circle.dayTimes);
  late int _duration = widget.circle.durationMinutes;

  List<String> get _days =>
      [for (final c in _scheduleDayOrder) if (_dayTimes.containsKey(c)) c];

  String get _commonTime =>
      _dayTimes.isEmpty ? '06:00' : _dayTimes.values.first;

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 6,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _fmtTime(String hhmm) {
    final t = _parseTime(hhmm);
    final period = t.hour < 12 ? 'ص' : 'م';
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h12:${t.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _edit() async {
    final result =
        await showDialog<({Set<String> days, TimeOfDay time, int duration})>(
      context: context,
      builder: (_) => _FixedScheduleEditor(
        initialDays: _days.toSet(),
        initialTime: _parseTime(_commonTime),
        initialDuration: _duration,
      ),
    );
    if (result == null) return;
    final hh = result.time.hour.toString().padLeft(2, '0');
    final mm = result.time.minute.toString().padLeft(2, '0');
    final map = {for (final d in result.days) d: '$hh:$mm'};
    setState(() {
      _dayTimes = map;
      _duration = result.duration;
    });
    try {
      await getIt<CircleRepository>().updateSchedule(
        circleId: widget.circle.id,
        dayTimes: map,
        durationMinutes: result.duration,
      );
      final newDays = [
        for (final c in _scheduleDayOrder)
          if (map.containsKey(c)) c
      ];
      widget.onChanged?.call(widget.circle.copyWith(
        days: newDays,
        dayTimes: map,
        durationMinutes: result.duration,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              const SnackBar(content: Text('تم تحديث الجدول الثابت')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('تعذّر حفظ الجدول')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _days;
    final hasRule = days.isNotEmpty;
    final label = hasRule
        ? days.map((d) => _scheduleDayLabels[d]).join(' · ')
        : 'لم يُحدَّد الجدول الثابت';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sky,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.event_repeat_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الجدول الثابت',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.primaryDark)),
                  const SizedBox(height: 2),
                  Text(hasRule ? '$label · ${_fmtTime(_commonTime)}' : label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (hasRule)
                    Text('مدة الجلسة $_duration دقيقة',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            if (widget.canManage)
              TextButton.icon(
                onPressed: _edit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(hasRule ? 'تعديل' : 'تحديد'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sessions generated from the fixed rule (no doc per occurrence):
/// القادمة (today + upcoming) and السجل (past, منتهية if attendance was taken
/// that day, else فائتة).
class _GeneratedSchedule extends StatefulWidget {
  final Circle circle;
  final AppUser user;
  final bool canManage;
  final VoidCallback? onAddExtra;
  const _GeneratedSchedule({
    required this.circle,
    required this.user,
    required this.canManage,
    this.onAddExtra,
  });

  @override
  State<_GeneratedSchedule> createState() => _GeneratedScheduleState();
}

class _GeneratedScheduleState extends State<_GeneratedSchedule> {
  List<DateTime> _upcoming = const [];
  List<DateTime> _past = const [];
  Map<String, Map<String, AttendanceState>> _att = const {};
  Map<String, ({String type, String? time})> _exc = const {};
  List<DateTime> _extras = const []; // one-off sessions outside the rule
  bool _loading = true;

  String _id(DateTime o) => DateFormat('yyyy-MM-dd').format(o);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 28));
    final to = today.add(const Duration(days: 28));

    Map<String, ({String type, String? time})> exc = const {};
    try {
      exc = await getIt<CircleRepository>()
          .getScheduleExceptions(widget.circle.id);
    } catch (_) {}

    // Step one: occurrences generated from the fixed rule.
    final byDate = <String, DateTime>{};
    final ruleIds = <String>{};
    for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      for (final entry in widget.circle.dayTimes.entries) {
        if (_codeToWeekday[entry.key] == d.weekday) {
          final dateId = DateFormat('yyyy-MM-dd').format(d);
          final e = exc[dateId];
          if (e != null && e.type == 'cancelled') continue; // skip cancelled
          final timeStr = (e != null && e.type == 'moved' && e.time != null)
              ? e.time!
              : entry.value;
          final p = timeStr.split(':');
          byDate[dateId] = DateTime(d.year, d.month, d.day,
              int.tryParse(p.first) ?? 6,
              int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
          ruleIds.add(dateId);
        }
      }
    }

    // Step two: real session docs the teacher created, one-off or materialized,
    //    merged in so added sessions actually appear in the schedule.
    final windowEnd = to.add(const Duration(days: 1));
    final extras = <DateTime>[];
    try {
      final docs = await getIt<SessionRepository>().getSessions(widget.circle.id);
      for (final s in docs) {
        final d = s.scheduledAt;
        if (d.isBefore(from) || !d.isBefore(windowEnd)) continue;
        final dateId = DateFormat('yyyy-MM-dd').format(d);
        if (exc[dateId]?.type == 'cancelled') continue;
        byDate[dateId] = d; // the real session's time wins
        if (!ruleIds.contains(dateId)) extras.add(d);
      }
    } catch (_) {}

    final occ = byDate.values.toList()..sort();
    extras.sort();
    final past = occ.where((o) => o.isBefore(today)).toList();
    final upcoming = occ.where((o) => !o.isBefore(today)).toList();
    final pastIds =
        past.map((o) => DateFormat('yyyy-MM-dd').format(o)).toList();
    Map<String, Map<String, AttendanceState>> att = const {};
    try {
      att = await getIt<CircleRepository>()
          .getWeekAttendance(circleId: widget.circle.id, dateIds: pastIds);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _past = past;
      _upcoming = upcoming;
      _att = att;
      _exc = exc;
      _extras = extras;
      _loading = false;
    });
  }

  Future<void> _cancelOccurrence(DateTime o) async {
    try {
      await getIt<CircleRepository>().setScheduleException(
        circleId: widget.circle.id,
        dateId: DateFormat('yyyy-MM-dd').format(o),
        type: 'cancelled',
      );
      await notifyCircleStudents(
        circleId: widget.circle.id,
        title: 'أُلغيت جلسة',
        body:
            '${widget.circle.name}: أُلغيت جلسة ${DateFormat('EEEE d MMMM', 'ar').format(o)}',
      );
      await _load();
    } catch (_) {
      _err();
    }
  }

  Future<void> _moveOccurrence(DateTime o) async {
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: o.hour, minute: o.minute));
    if (picked == null) return;
    final t =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    try {
      await getIt<CircleRepository>().setScheduleException(
        circleId: widget.circle.id,
        dateId: DateFormat('yyyy-MM-dd').format(o),
        type: 'moved',
        time: t,
      );
      await notifyCircleStudents(
        circleId: widget.circle.id,
        title: 'تغيّر موعد جلسة',
        body:
            '${widget.circle.name}: أصبحت جلسة ${DateFormat('EEEE d MMMM', 'ar').format(o)} في $t',
      );
      await _load();
    } catch (_) {
      _err();
    }
  }

  void _err() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تعذّر تحديث الجلسة')));
  }

  bool _isToday(DateTime o) {
    final n = DateTime.now();
    return o.year == n.year && o.month == n.month && o.day == n.day;
  }

  /// Materialize-on-start: turn today's generated occurrence into a real
  /// session, start it live, and open the live screen.
  Future<void> _startToday(DateTime o) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final session = await getIt<CalendarRepository>().addSession(
        circleId: widget.circle.id,
        title: 'جلسة ${widget.circle.name}',
        scheduledAt: o,
        durationMinutes: widget.circle.durationMinutes,
        type: SessionType.tasmi3,
      );
      await getIt<SessionRepository>()
          .startSession(circleId: widget.circle.id, sessionId: session.id);
      if (!mounted) return;
      nav.push(MaterialPageRoute(
        builder: (_) =>
            LiveSessionPage(circleId: widget.circle.id, user: widget.user),
      ));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تعذّر بدء الجلسة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final todays = _upcoming.where(_isToday).toList();
    final today = todays.isEmpty ? null : todays.first;
    final laters = _upcoming.where((o) => !_isToday(o)).toList();
    final next = laters.isEmpty ? null : laters.first;

    final now = DateTime.now();
    final from =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 28));
    final exc = <({DateTime date, String type, String? time})>[
      ..._exc.entries
          .map((e) => (
                date: DateTime.tryParse(e.key) ?? from,
                type: e.value.type,
                time: e.value.time,
              ))
          .where((x) => !x.date.isBefore(from)),
      ..._extras.map((d) => (
            date: d,
            type: 'extra',
            time:
                '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
          )),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final held = _past.where((o) => _att[_id(o)]?.isNotEmpty ?? false).length;
    final notHeld = _past.length - held;
    final ratios = <double>[];
    for (final o in _past) {
      final m = _att[_id(o)];
      if (m != null && m.isNotEmpty) {
        final present =
            m.values.where((s) => s == AttendanceState.present).length;
        ratios.add(present / m.length);
      }
    }
    final avg = ratios.isEmpty
        ? null
        : (ratios.reduce((a, b) => a + b) / ratios.length * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      children: [
        _actionCard(theme, today, next),
        const SizedBox(height: AppSpacing.md),
        _exceptionsCard(theme, exc),
        const SizedBox(height: AppSpacing.md),
        _historyCard(theme, held, notHeld, avg),
      ],
    );
  }

  // ── today / next action card ───────────────────────────────
  Widget _actionCard(ThemeData theme, DateTime? today, DateTime? next) {
    final fmt = DateFormat('EEEE d MMMM • h:mm a', 'ar');
    if (today == null && next == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.event_busy_outlined, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text('لا جلسات قادمة',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted)),
        ]),
      );
    }
    final show = today ?? next!;
    final isToday = today != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: isToday ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_outlined,
                  size: 16,
                  color: isToday ? Colors.white70 : AppColors.primary),
              const SizedBox(width: 6),
              Text(isToday ? 'جلسة اليوم' : 'الجلسة القادمة',
                  style: TextStyle(
                      fontSize: 12,
                      color: isToday ? Colors.white70 : AppColors.textMuted)),
              const Spacer(),
              if (widget.canManage)
                _occMenu(show, light: isToday),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(fmt.format(show),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isToday ? Colors.white : AppColors.ink)),
              ),
              if (isToday && widget.canManage)
                FilledButton.icon(
                  onPressed: () => _startToday(show),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('بدء'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact),
                ),
            ],
          ),
          Text('مدة ${widget.circle.durationMinutes} دقيقة',
              style: TextStyle(
                  fontSize: 11,
                  color: isToday ? Colors.white70 : AppColors.textMuted)),
          if (isToday && next != null) ...[
            const SizedBox(height: 8),
            Text('التالية: ${fmt.format(next)}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  Widget _occMenu(DateTime o, {required bool light}) => PopupMenuButton<String>(
        tooltip: 'خيارات',
        icon: Icon(Icons.more_horiz,
            color: light ? Colors.white : AppColors.textMuted),
        onSelected: (v) {
          if (v == 'move') _moveOccurrence(o);
          if (v == 'cancel') _cancelOccurrence(o);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'move', child: Text('تعديل الوقت')),
          PopupMenuItem(
            value: 'cancel',
            child: Text('إلغاء هذه الجلسة',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      );

  // ── exceptions only ────────────────────────────────────────
  Widget _exceptionsCard(
      ThemeData theme,
      List<({DateTime date, String type, String? time})> exc) {
    final dF = DateFormat('EEEE d MMMM', 'ar');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.event_repeat_outlined,
                    size: 17, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('الاستثناءات', style: theme.textTheme.titleSmall),
              ]),
              if (widget.onAddExtra != null)
                TextButton.icon(
                  onPressed: widget.onAddExtra,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('جلسة استثنائية'),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),
            ],
          ),
          if (exc.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('لا استثناءات — الجلسات تسير وفق الجدول الثابت',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted)),
            )
          else
            for (final x in exc)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (x.type == 'cancelled'
                                ? AppColors.error
                                : x.type == 'extra'
                                    ? AppColors.primary
                                    : AppColors.warning)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                          x.type == 'cancelled'
                              ? Icons.event_busy_outlined
                              : x.type == 'extra'
                                  ? Icons.event_available_outlined
                                  : Icons.update,
                          size: 17,
                          color: x.type == 'cancelled'
                              ? AppColors.error
                              : x.type == 'extra'
                                  ? AppColors.primary
                                  : AppColors.warning),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        x.type == 'cancelled'
                            ? '${dF.format(x.date)} — أُلغيت'
                            : x.type == 'extra'
                                ? '${dF.format(x.date)} — جلسة إضافية ${x.time ?? ''}'
                                : '${dF.format(x.date)} — نُقلت إلى ${x.time ?? ''}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // ── compact month history ──────────────────────────────────
  Widget _historyCard(ThemeData theme, int held, int notHeld, int? avg) {
    Widget tile(String v, String l, Color bg, Color fg) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(v,
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 2),
                Text(l,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: fg)),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.history, size: 17, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('سجل آخر ٤ أسابيع', style: theme.textTheme.titleSmall),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              tile('$held', 'جلسة منعقدة', const Color(0xFFE1F5EE),
                  const Color(0xFF0F6E56)),
              const SizedBox(width: 8),
              tile('$notHeld', 'لم تُعقد', AppColors.gray, AppColors.textMuted),
              const SizedBox(width: 8),
              tile(avg == null ? '—' : '$avg٪', 'متوسط الحضور',
                  const Color(0xFFFAEEDA), const Color(0xFF854F0B)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FixedScheduleEditor extends StatefulWidget {
  final Set<String> initialDays;
  final TimeOfDay initialTime;
  final int initialDuration;
  const _FixedScheduleEditor({
    required this.initialDays,
    required this.initialTime,
    required this.initialDuration,
  });

  @override
  State<_FixedScheduleEditor> createState() => _FixedScheduleEditorState();
}

class _FixedScheduleEditorState extends State<_FixedScheduleEditor> {
  late final Set<String> _days = {...widget.initialDays};
  late TimeOfDay _time = widget.initialTime;
  late int _duration = widget.initialDuration;

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0),
      title: Row(
        children: [
          const Expanded(child: Text('الجدول الثابت')),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'إلغاء',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('أيام الحلقة',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in _scheduleDayOrder)
                    FilterChip(
                      label: Text(_scheduleDayLabels[c]!),
                      selected: _days.contains(c),
                      onSelected: (v) => setState(
                          () => v ? _days.add(c) : _days.remove(c)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_outlined),
                title: const Text('وقت البدء'),
                subtitle: Text(_time.format(context)),
                trailing: TextButton(
                    onPressed: _pickTime, child: const Text('تغيير')),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('مدة الجلسة',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final d in [30, 45, 60, 90])
                    ChoiceChip(
                      label: Text('$d د'),
                      selected: _duration == d,
                      onSelected: (_) => setState(() => _duration = d),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _days.isEmpty
                    ? null
                    : () => Navigator.of(context).pop((
                          days: _days,
                          time: _time,
                          duration: _duration,
                        )),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SessionCard({
    required this.session,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('HH:mm');
    final color = _sessionTypeColor(session.type);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(
                  session.type == SessionType.imla2
                      ? Icons.edit_note_outlined
                      : Icons.record_voice_over_outlined,
                  color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${fmt.format(session.scheduledAt)} - ${fmt.format(session.endsAt)} · ${session.type.arabicLabel}${session.isRecurring ? ' · أسبوعية' : ''}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (canManage) ...[
              IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary)),
              IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Add/edit a session — supports an optional weekly-repeat that generates
/// one session per occurrence.
class _SessionForm extends StatefulWidget {
  final CalendarBloc bloc;
  final String circleId;
  final Session? initial;
  const _SessionForm(
      {required this.bloc, required this.circleId, this.initial});

  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  late final TextEditingController _title =
      TextEditingController(text: widget.initial?.title ?? '');
  late DateTime _date = widget.initial?.scheduledAt ?? DateTime.now();
  late TimeOfDay _time = TimeOfDay.fromDateTime(
      widget.initial?.scheduledAt ?? DateTime.now());
  late int _duration = widget.initial?.durationMinutes ?? 60;
  late SessionType _type = widget.initial?.type ?? SessionType.tasmi3;
  bool _repeat = false;
  final Set<int> _weekdays = {};
  late DateTime _until = DateTime.now().add(const Duration(days: 28));

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (p != null) setState(() => _date = p);
  }

  Future<void> _pickUntil() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _until,
      firstDate: _date,
      lastDate: DateTime(2035, 12, 31),
    );
    if (p != null) setState(() => _until = p);
  }

  Future<void> _pickTime() async {
    final p = await showTimePicker(context: context, initialTime: _time);
    if (p != null) setState(() => _time = p);
  }

  List<DateTime> _occurrences() {
    final out = <DateTime>[];
    var d = DateTime(_date.year, _date.month, _date.day);
    final end = DateTime(_until.year, _until.month, _until.day);
    var guard = 0;
    while (!d.isAfter(end) && guard < 200) {
      if (_weekdays.contains(d.weekday)) {
        out.add(DateTime(d.year, d.month, d.day, _time.hour, _time.minute));
      }
      d = d.add(const Duration(days: 1));
      guard++;
    }
    return out;
  }

  void _submit() {
    // Title is optional — default to the session type label.
    final title =
        _title.text.trim().isEmpty ? _type.arabicLabel : _title.text.trim();
    final at = DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute);
    if (_isEdit) {
      widget.bloc.add(CalendarSessionUpdated(
        circleId: widget.circleId,
        sessionId: widget.initial!.id,
        title: title,
        scheduledAt: at,
        durationMinutes: _duration,
        type: _type,
      ));
    } else if (_repeat && _weekdays.isNotEmpty) {
      widget.bloc.add(CalendarRecurringSessionsAdded(
        circleId: widget.circleId,
        title: title,
        type: _type,
        durationMinutes: _duration,
        occurrences: _occurrences(),
      ));
    } else {
      widget.bloc.add(CalendarSessionAdded(
        circleId: widget.circleId,
        title: title,
        scheduledAt: at,
        durationMinutes: _duration,
        type: _type,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE d MMMM', 'ar');
    final timeLabel =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل الجلسة' : 'جلسة جديدة'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<SessionType>(
                segments: const [
                  ButtonSegment(value: SessionType.tasmi3, label: Text('تسميع')),
                  ButtonSegment(value: SessionType.imla2, label: Text('إملاء')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(dateFmt.format(_date)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time, size: 16),
                label: Text('الوقت: $timeLabel'),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'المدة', isDense: true),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _duration,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                      DropdownMenuItem(value: 45, child: Text('45 دقيقة')),
                      DropdownMenuItem(value: 60, child: Text('60 دقيقة')),
                      DropdownMenuItem(value: 90, child: Text('90 دقيقة')),
                    ],
                    onChanged: (v) => setState(() => _duration = v ?? 60),
                  ),
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('تكرار أسبوعي'),
                  value: _repeat,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _repeat = v),
                ),
                if (_repeat) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final code in _scheduleDayOrder)
                        FilterChip(
                          label: Text(_scheduleDayLabels[code]!),
                          selected:
                              _weekdays.contains(_codeToWeekday[code]),
                          onSelected: (sel) => setState(() {
                            final wd = _codeToWeekday[code]!;
                            if (sel) {
                              _weekdays.add(wd);
                            } else {
                              _weekdays.remove(wd);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _pickUntil,
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text('حتى ${dateFmt.format(_until)}'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء')),
        ElevatedButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
//  الطالبات tab
// ---------------------------------------------------------------------------

class _StudentsTab extends StatelessWidget {
  final Circle circle;
  final bool canManage;
  const _StudentsTab({required this.circle, required this.canManage});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CircleBloc>()..add(CircleMembersRequested(circle.id)),
      child: _StudentsView(circle: circle, canManage: canManage),
    );
  }
}

class _StudentsView extends StatefulWidget {
  final Circle circle;
  final bool canManage;
  const _StudentsView({required this.circle, required this.canManage});

  @override
  State<_StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<_StudentsView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CircleBloc, CircleState>(
        listenWhen: (p, c) => c.message.isNotEmpty && p.message != c.message,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = state.members
              .where((m) => m.role == UserRole.student)
              .where((m) => m.name.contains(_query.trim()))
              .toList()
            // follow-up priority: lowest memorization first
            ..sort((a, b) => a.memorizedPercent.compareTo(b.memorizedPercent));

          return Column(
            children: [
              _StudentsToolbar(
                canManage: widget.canManage,
                onSearch: (v) => setState(() => _query = v),
                onAdd: () => _addStudent(context),
                onExport: () => _exportCsv(students),
              ),
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Text('لا توجد طالبات بعد',
                            style: Theme.of(context).textTheme.bodyMedium),
                      )
                    : LayoutBuilder(builder: (context, c) {
                        final onEdit = widget.canManage
                            ? (CircleMember m) => _editStudent(context, m)
                            : null;
                        if (c.maxWidth >= 720) {
                          return _StudentsTable(
                              circle: widget.circle,
                              students: students,
                              onEdit: onEdit);
                        }
                        final names = {
                          for (final s in students) s.uid: s.name
                        };
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md, 4, AppSpacing.md, 24),
                          itemCount: students.length,
                          itemBuilder: (context, i) {
                            final m = students[i];
                            return _StudentCard(
                              member: m,
                              canManage: widget.canManage,
                              partnerName: m.partnerId == null
                                  ? null
                                  : names[m.partnerId],
                              onTap: onEdit == null
                                  ? null
                                  : () => onEdit(m),
                            );
                          },
                        );
                      }),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addStudent(BuildContext context) async {
    final bloc = context.read<CircleBloc>();
    final nameController = TextEditingController();
    final juzController = TextEditingController();
    final contactController = TextEditingController();
    var hasAccount = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setLocal) => AlertDialog(
          title: const Text('إضافة طالبة'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('بدون حساب')),
                    ButtonSegment(value: true, label: Text('لديها حساب')),
                  ],
                  selected: {hasAccount},
                  onSelectionChanged: (s) =>
                      setLocal(() => hasAccount = s.first),
                ),
                const SizedBox(height: 16),
                if (hasAccount) ...[
                  TextField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني أو رقم الهاتف',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نبحث عن حسابها ونضيفها للحلقة مباشرة.',
                    style: Theme.of(dialogCtx)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ] else ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم الطالبة'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: juzController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'الجزء (اختياري)'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تُضاف بالاسم فقط للمتابعة (بدون تسجيل دخول).',
                    style: Theme.of(dialogCtx)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (hasAccount) {
                  if (contactController.text.trim().isEmpty) return;
                  bloc.add(CircleStudentLinkedByContact(
                    circleId: widget.circle.id,
                    contact: contactController.text.trim(),
                  ));
                } else {
                  if (nameController.text.trim().isEmpty) return;
                  bloc.add(CircleStudentAdded(
                    circleId: widget.circle.id,
                    name: nameController.text,
                    juz: int.tryParse(juzController.text.trim()),
                  ));
                }
                Navigator.pop(dialogCtx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _editStudent(BuildContext context, CircleMember member) {
    final bloc = context.read<CircleBloc>();
    showDialog(
      context: context,
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: SizedBox(
            width: w < 520 ? w - 48 : 460,
            child: _StudentEditor(
              circleId: widget.circle.id,
              member: member,
              bloc: bloc,
            ),
          ),
        );
      },
    );
  }

  String _csvCell(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  Future<void> _exportCsv(List<CircleMember> students) async {
    final rows = <List<String>>[
      ['الطالبة', 'الجزء', 'الحضور', 'تقدّم الحفظ %', 'الحالة', 'آخر تسميع'],
      for (final m in students)
        [
          m.name,
          m.juz?.toString() ?? '',
          m.attendance?.arabicLabel ?? '',
          m.memorizedPercent.toString(),
          m.performance?.arabicLabel ?? '',
          m.lastRecitationAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(m.lastRecitationAt!)
              : '',
        ],
    ];
    final csv = rows.map((r) => r.map(_csvCell).join(',')).join('\r\n');
    // Prefix a BOM so Excel opens the Arabic text correctly.
    final bytes = Uint8List.fromList(utf8.encode('﻿$csv'));
    final safe = widget.circle.name.replaceAll(RegExp(r'\s+'), '_');
    try {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'text/csv', name: 'students_$safe.csv')],
        text: 'قائمة طالبات ${widget.circle.name}',
      );
    } catch (_) {
      // Sharing files isn't supported everywhere (e.g. desktop web) — copy
      // the CSV text to the clipboard instead so nothing crashes.
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذّرت المشاركة — تم نسخ القائمة إلى الحافظة')));
      }
    }
  }
}

class _StudentCard extends StatelessWidget {
  final CircleMember member;
  final bool canManage;
  final String? partnerName;
  final VoidCallback? onTap;

  const _StudentCard(
      {required this.member,
      required this.canManage,
      this.partnerName,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = member.name.isNotEmpty ? member.name.characters.first : '؟';
    final last = member.lastRecitationAt;
    final lastLabel = last == null
        ? 'لم تُسمّع بعد'
        : 'آخر تسميع ${DateFormat('d/M h:mm', 'ar').format(last)}';
    final pending = member.status == MemberStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(initial,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: theme.textTheme.titleMedium),
                        Text(
                          [
                            if (member.juz != null) 'جزء ${member.juz}',
                            lastLabel,
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (pending)
                    const StatusChip(label: 'بانتظار القبول', color: AppColors.warning)
                  else
                    StatusChip(
                      label: member.attendance?.arabicLabel ?? '—',
                      color: attendanceColor(member.attendance),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: member.memorizedRatio,
                        minHeight: 7,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${member.memorizedPercent}%',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(width: 10),
                  StatusChip(
                    label: member.performance?.arabicLabel ?? 'بلا تقييم',
                    color: performanceColor(member.performance),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text('الشريكة: ',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted)),
                  Expanded(
                    child: Text(
                      (partnerName == null || partnerName!.isEmpty)
                          ? 'لا توجد'
                          : partnerName!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet editor for one enrollment (per-circle data only).
class _StudentEditor extends StatefulWidget {
  final String circleId;
  final CircleMember member;
  final CircleBloc bloc;

  const _StudentEditor(
      {required this.circleId, required this.member, required this.bloc});

  @override
  State<_StudentEditor> createState() => _StudentEditorState();
}

class _StudentEditorState extends State<_StudentEditor> {
  late AttendanceState? _attendance = widget.member.attendance;
  late PerformanceTag? _performance = widget.member.performance;
  late int _pages = widget.member.memorizedPages;
  late final TextEditingController _contact =
      TextEditingController(text: widget.member.contact ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.member.notes ?? '');

  @override
  void dispose() {
    _contact.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save({bool recite = false}) {
    widget.bloc.add(CircleMemberUpdated(
      circleId: widget.circleId,
      uid: widget.member.uid,
      attendance: _attendance,
      performance: _performance,
      memorizedPages: _pages,
      contact: _contact.text.trim(),
      notes: _notes.text.trim(),
      touchRecitation: recite,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(widget.member.name,
                  style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('الحضور', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final a in AttendanceState.values)
                  ChoiceChip(
                    label: Text(a.arabicLabel),
                    selected: _attendance == a,
                    onSelected: (_) => setState(() => _attendance = a),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Text('التقييم', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in PerformanceTag.values)
                  ChoiceChip(
                    label: Text(p.arabicLabel),
                    selected: _performance == p,
                    onSelected: (_) => setState(() => _performance = p),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Text('الحفظ: $_pages صفحة', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final n in [1, 5, 10])
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _pages += n),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(56, 40)),
                      child: Text('+$n'),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: _pages > 0 ? () => setState(() => _pages -= 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'جهة الاتصال / ولي الأمر',
                prefixIcon: Icon(Icons.contact_phone_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات المعلّمة',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            ElevatedButton.icon(
              onPressed: () => _save(recite: true),
              icon: const Icon(Icons.mic_none),
              label: const Text('حفظ + تسجيل تسميع الآن'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _save(),
              child: const Text('حفظ التعديلات'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                widget.bloc.add(CircleMemberRemoved(
                    circleId: widget.circleId, uid: widget.member.uid));
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: const Text('حذف الطالبة',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Students toolbar (search + add + export)
// ---------------------------------------------------------------------------

class _StudentsToolbar extends StatelessWidget {
  final bool canManage;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;
  final VoidCallback onExport;
  const _StudentsToolbar({
    required this.canManage,
    required this.onSearch,
    required this.onAdd,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      onChanged: onSearch,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'بحث عن طالبة...',
        prefixIcon: Icon(Icons.search),
      ),
    );
    final add = ElevatedButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.person_add_alt, size: 18),
      label: const Text('إضافة طالبة'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
    );
    final export = OutlinedButton.icon(
      onPressed: onExport,
      icon: const Icon(Icons.file_download_outlined, size: 18),
      label: const Text('تصدير القائمة'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= 720) {
          return Row(
            children: [
              if (canManage) ...[
                add,
                const SizedBox(width: 8),
                export,
              ],
              const Spacer(),
              SizedBox(width: 280, child: search),
            ],
          );
        }
        return Column(
          children: [
            search,
            if (canManage) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: add),
                const SizedBox(width: 8),
                Expanded(child: export),
              ]),
            ],
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
//  Students table (wide screens)
// ---------------------------------------------------------------------------

class _StudentsTable extends StatefulWidget {
  final Circle circle;
  final List<CircleMember> students;
  final void Function(CircleMember)? onEdit;
  const _StudentsTable(
      {required this.circle, required this.students, required this.onEdit});

  @override
  State<_StudentsTable> createState() => _StudentsTableState();
}

/// Per-student weekly rollup powering the summary table.
class _WeekRollup {
  final int attended; // حضرت/تأخّرت في جلسات هذا الأسبوع
  final int held; // عدد جلسات هذا الأسبوع التي انعقدت حتى اليوم
  final Set<String> doneDays; // أيام التسميع اليومي التي سجّلتها الطالبة
  final ({bool done, String grade})? hifz; // تقييم الحفظ (null = لم يُسجَّل)
  const _WeekRollup({
    required this.attended,
    required this.held,
    required this.doneDays,
    required this.hifz,
  });
}

class _StudentsTableState extends State<_StudentsTable> {
  late String _amount = widget.circle.hifzAmount;

  // --- this week ---
  late final DateTime _weekStart; // السبت
  late final String _weekId;
  late final DateTime _today;
  int _daysElapsed = 1; // الأيام المنقضية من الأسبوع (مقام التسميع اليومي)
  List<String> _sessionCodes = const []; // أيام جلسات الحلقة هذا الأسبوع
  List<String> _occurredDateIds = const []; // المنعقدة حتى اليوم

  // --- loaded data ---
  Map<String, Map<String, AttendanceState>> _att = {}; // dateId → uid → state
  Map<String, ({bool done, String grade})> _hifz = {}; // uid → mark
  Map<String, Set<String>> _doneDays = {}; // uid → أيام التسميع
  bool _loading = true;

  bool get _canManage => widget.onEdit != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final sinceSat = (_today.weekday - DateTime.saturday) % 7;
    _weekStart = _today.subtract(Duration(days: sinceSat));
    _weekId = DateFormat('yyyy-MM-dd').format(_weekStart);
    _daysElapsed = sinceSat + 1;
    _sessionCodes = [
      for (final c in _scheduleDayOrder)
        if (widget.circle.days.contains(c)) c,
    ];
    _occurredDateIds = [
      for (final c in _sessionCodes)
        if (_scheduleDayOrder.indexOf(c) <= sinceSat)
          DateFormat('yyyy-MM-dd').format(
              _weekStart.add(Duration(days: _scheduleDayOrder.indexOf(c)))),
    ];
    _load();
  }

  Future<void> _load() async {
    final id = widget.circle.id;
    Map<String, Map<String, AttendanceState>> att = {};
    try {
      att = await getIt<CircleRepository>()
          .getWeekAttendance(circleId: id, dateIds: _occurredDateIds);
    } catch (_) {}
    Map<String, ({bool done, String grade})> hifz = {};
    try {
      final w = await getIt<CircleRepository>()
          .getHifzWeeks(circleId: id, weekIds: [_weekId]);
      hifz = w[_weekId] ?? {};
    } catch (_) {}
    final done = <String, Set<String>>{};
    try {
      final comps = await HomeworkRepository(
              getIt<FirebaseFirestore>(), getIt<FirebaseAuth>())
          .completionsStream(id, _weekId)
          .first;
      for (final c in comps) {
        done[c.uid] = c.doneDays;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _att = att;
      _hifz = hifz;
      _doneDays = done;
      _loading = false;
    });
  }

  _WeekRollup _rollupFor(String uid) {
    var attended = 0;
    for (final d in _occurredDateIds) {
      final s = _att[d]?[uid];
      if (s == AttendanceState.present || s == AttendanceState.late_) {
        attended++;
      }
    }
    return _WeekRollup(
      attended: attended,
      held: _occurredDateIds.length,
      doneDays: _doneDays[uid] ?? const {},
      hifz: _hifz[uid],
    );
  }

  AttendanceState? _nextAtt(AttendanceState? s) {
    switch (s) {
      case null:
        return AttendanceState.present;
      case AttendanceState.present:
        return AttendanceState.absent;
      case AttendanceState.absent:
        return AttendanceState.excused;
      default:
        return null;
    }
  }

  Future<void> _cycleAtt(String uid, String dateId) async {
    final next = _nextAtt(_att[dateId]?[uid]);
    setState(() {
      final m = _att.putIfAbsent(dateId, () => {});
      if (next == null) {
        m.remove(uid);
      } else {
        m[uid] = next;
      }
    });
    try {
      await getIt<CircleRepository>().markAttendance(
          circleId: widget.circle.id, dateId: dateId, uid: uid, state: next);
    } catch (_) {
      if (mounted) _load();
    }
  }

  Future<void> _editHifz(CircleMember m) async {
    if (!_canManage) return;
    final cur = _hifz[m.uid];
    var done = cur?.done ?? true;
    var grade = (cur != null && cur.grade.isNotEmpty)
        ? cur.grade
        : PerformanceTag.good.name;
    final res = await showDialog<({bool? done, String grade})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('الحفظ الأسبوعي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_amount.trim().isNotEmpty)
                Text('المطلوب: $_amount',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('أتمّت')),
                  ButtonSegment(value: false, label: Text('لم تُكمل')),
                ],
                selected: {done},
                onSelectionChanged: (s) => setLocal(() => done = s.first),
              ),
              if (done) ...[
                const SizedBox(height: 14),
                const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('التقييم', style: TextStyle(fontSize: 12))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in PerformanceTag.values)
                      ChoiceChip(
                        label: Text(t.arabicLabel),
                        selected: grade == t.name,
                        onSelected: (_) => setLocal(() => grade = t.name),
                      ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            if (cur != null)
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, (done: null, grade: '')),
                child: const Text('مسح'),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(
                  ctx, (done: done, grade: done ? grade : '')),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (res == null) return;
    setState(() {
      if (res.done == null) {
        _hifz.remove(m.uid);
      } else {
        _hifz[m.uid] = (done: res.done!, grade: res.grade);
      }
    });
    try {
      await getIt<CircleRepository>().markHifz(
        circleId: widget.circle.id,
        weekId: _weekId,
        uid: m.uid,
        done: res.done,
        grade: res.grade,
      );
    } catch (_) {
      if (mounted) _load();
    }
  }

  Future<void> _editAmount() async {
    final controller = TextEditingController(text: _amount);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مقدار الحفظ الأسبوعي'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'مثال: وجه، نصف صفحة، ٥ آيات…',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (result == null) return;
    setState(() => _amount = result);
    try {
      await getIt<CircleRepository>()
          .updateHifzAmount(circleId: widget.circle.id, amount: result);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = {for (final s in widget.students) s.uid: s.name};
    Widget head(String t, int flex) => Expanded(
          flex: flex,
          child: Text(t,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Column(
        children: [
          _HifzAmountBanner(
            amount: _amount,
            onEdit: _canManage ? _editAmount : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    color: AppColors.gray,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        head('الطالبة', 3),
                        head('حضور الجلسات', 2),
                        head('التسميع اليومي', 2),
                        head('الحفظ الأسبوعي', 3),
                        head('الشريكة', 2),
                        head('', 1),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: widget.students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final m = widget.students[i];
                        return _StudentRow(
                          circle: widget.circle,
                          member: m,
                          onEdit: widget.onEdit,
                          partnerName:
                              m.partnerId == null ? null : names[m.partnerId],
                          loading: _loading,
                          rollup: _rollupFor(m.uid),
                          daysElapsed: _daysElapsed,
                          today: _today,
                          weekStart: _weekStart,
                          sessionCodes: _sessionCodes,
                          attOf: (dateId) => _att[dateId]?[m.uid],
                          onCycleAtt: _canManage
                              ? (dateId) => _cycleAtt(m.uid, dateId)
                              : null,
                          onEditHifz:
                              _canManage ? () => _editHifz(m) : null,
                        );
                      },
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

/// Banner above the students table showing the حلقة's «مقدار الحفظ الأسبوعي»
/// with an edit affordance for managers.
class _HifzAmountBanner extends StatelessWidget {
  final String amount;
  final VoidCallback? onEdit;
  const _HifzAmountBanner({required this.amount, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final has = amount.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('مقدار الحفظ الأسبوعي: ',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
          Expanded(
            child: Text(
              has ? amount : 'لم يُحدَّد بعد',
              style: theme.textTheme.titleSmall?.copyWith(
                color: has ? AppColors.ink : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onEdit != null)
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(has ? 'تعديل' : 'تحديد'),
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatefulWidget {
  final Circle circle;
  final CircleMember member;
  final void Function(CircleMember)? onEdit;
  final String? partnerName;
  final bool loading;
  final _WeekRollup rollup;
  final int daysElapsed;
  final DateTime today;
  final DateTime weekStart;
  final List<String> sessionCodes;
  final AttendanceState? Function(String dateId) attOf;
  final void Function(String dateId)? onCycleAtt;
  final VoidCallback? onEditHifz;
  const _StudentRow({
    required this.circle,
    required this.member,
    required this.onEdit,
    required this.loading,
    required this.rollup,
    required this.daysElapsed,
    required this.today,
    required this.weekStart,
    required this.sessionCodes,
    required this.attOf,
    required this.onCycleAtt,
    required this.onEditHifz,
    this.partnerName,
  });

  @override
  State<_StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<_StudentRow> {
  bool _expanded = false;

  Widget _hifzChip() {
    final h = widget.rollup.hifz;
    if (widget.loading) {
      return Text('…',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
    Widget chip;
    if (h == null) {
      chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: AppColors.border, style: BorderStyle.solid),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add, size: 13, color: AppColors.textMuted),
          SizedBox(width: 3),
          Text('تسجيل الحفظ',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        ]),
      );
    } else if (h.done) {
      final tag = PerformanceTag.fromName(h.grade);
      final label =
          tag == null ? 'حفِظت' : 'حفِظت · ${tag.arabicLabel}';
      chip = _pill(label, AppColors.success, Icons.check_circle_rounded);
    } else {
      chip = _pill('لم تُكمل', AppColors.warning, Icons.schedule_rounded);
    }
    if (widget.onEditHifz == null) return chip;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: widget.onEditHifz,
      child: chip,
    );
  }

  Widget _pill(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _count(int x, int y, String unit) {
    if (widget.loading) {
      return Text('…',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
    if (y == 0) {
      return Text('—',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
    return RichText(
      text: TextSpan(children: [
        TextSpan(
            text: '$x / $y ',
            style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        TextSpan(
            text: unit,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;
    final initial = member.name.isNotEmpty ? member.name.characters.first : '؟';
    final pending = member.status == MemberStatus.pending;
    final partner = widget.partnerName;
    final r = widget.rollup;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // الطالبة
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.sky,
                        child: Text(initial,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall),
                            if (pending)
                              const Text('بانتظار',
                                  style: TextStyle(
                                      color: AppColors.warning, fontSize: 11))
                            else if (member.juz != null)
                              Text('جزء ${member.juz}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // حضور الجلسات
                Expanded(
                    flex: 2, child: _count(r.attended, r.held, 'جلسة')),
                // التسميع اليومي
                Expanded(
                  flex: 2,
                  child: _count(r.doneDays.length, widget.daysElapsed, 'يوم'),
                ),
                // الحفظ الأسبوعي
                Expanded(
                  flex: 3,
                  child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _hifzChip()),
                ),
                // الشريكة
                Expanded(
                  flex: 2,
                  child: (partner == null || partner.isEmpty)
                      ? Text('—',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primary,
                              child: Text(partner.characters.first,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(partner,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall),
                            ),
                          ],
                        ),
                ),
                // إجراءات
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEdit != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.primary),
                          onPressed: () => widget.onEdit!(member),
                        ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          _StudentWeekDetail(
            today: widget.today,
            weekStart: widget.weekStart,
            sessionCodes: widget.sessionCodes,
            doneDays: r.doneDays,
            attOf: widget.attOf,
            onCycleAtt: widget.onCycleAtt,
          ),
      ],
    );
  }
}

/// Expanded panel under a table row: the day-by-day breakdown.
/// Top strip = daily تسميع ticks (read-only, the student's own). Bottom strip
/// = this week's session attendance (tappable by managers).
class _StudentWeekDetail extends StatelessWidget {
  final DateTime today;
  final DateTime weekStart;
  final List<String> sessionCodes;
  final Set<String> doneDays;
  final AttendanceState? Function(String dateId) attOf;
  final void Function(String dateId)? onCycleAtt;
  const _StudentWeekDetail({
    required this.today,
    required this.weekStart,
    required this.sessionCodes,
    required this.doneDays,
    required this.attOf,
    required this.onCycleAtt,
  });

  Color _attColor(AttendanceState? s) => attendanceColor(s);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: AppColors.beige,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock_outline, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('التسميع اليومي مع الرفيقة',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final code in _scheduleDayOrder)
                _dayTick(code),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.event_available_outlined,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('حضور الجلسات',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.primary)),
          ]),
          const SizedBox(height: 8),
          if (sessionCodes.isEmpty)
            Text('لا توجد أيام جلسات محدَّدة لهذه الحلقة',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in sessionCodes) _sessionChip(code),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dayTick(String code) {
    final idx = _scheduleDayOrder.indexOf(code);
    final date = weekStart.add(Duration(days: idx));
    final future = date.isAfter(today);
    final done = doneDays.contains(code);
    final Color bg, fg;
    final IconData icon;
    if (done) {
      bg = AppColors.success.withValues(alpha: .14);
      fg = AppColors.success;
      icon = Icons.check;
    } else if (future) {
      bg = AppColors.gray;
      fg = AppColors.textMuted.withValues(alpha: .5);
      icon = Icons.remove;
    } else {
      bg = AppColors.gray;
      fg = AppColors.textMuted;
      icon = Icons.close;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: fg),
        ),
        const SizedBox(height: 3),
        Text(_scheduleDayLabels[code] ?? code,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _sessionChip(String code) {
    final idx = _scheduleDayOrder.indexOf(code);
    final date = weekStart.add(Duration(days: idx));
    final dateId = DateFormat('yyyy-MM-dd').format(date);
    final occurred = !date.isAfter(today);
    final label = _scheduleDayLabels[code] ?? code;
    if (!occurred) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('$label · لاحقًا',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted)),
      );
    }
    final state = attOf(dateId);
    final color = _attColor(state);
    final text = '$label · ${state?.arabicLabel ?? 'لم تُسجَّل'}';
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: state == null
            ? AppColors.surface
            : color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: state == null ? AppColors.border : color),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              color: state == null ? AppColors.textMuted : color,
              fontWeight: FontWeight.w600)),
    );
    if (onCycleAtt == null) return chip;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onCycleAtt!(dateId),
      child: chip,
    );
  }
}
