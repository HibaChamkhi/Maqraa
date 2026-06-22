import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import '../../../core/data/quran_surahs.dart';
import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/util/last_location_store.dart';
import '../../../core/ui/styles/theme.dart';
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
        width: double.maxFinite,
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
  late final List<DateTime> _upcoming;
  late final List<DateTime> _past;
  late final Future<Map<String, Map<String, AttendanceState>>> _att;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 28));
    final to = today.add(const Duration(days: 28));
    final occ = <DateTime>[];
    for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      for (final entry in widget.circle.dayTimes.entries) {
        if (_codeToWeekday[entry.key] == d.weekday) {
          final p = entry.value.split(':');
          occ.add(DateTime(d.year, d.month, d.day,
              int.tryParse(p.first) ?? 6,
              int.tryParse(p.length > 1 ? p[1] : '0') ?? 0));
        }
      }
    }
    occ.sort();
    _past = occ.where((o) => o.isBefore(today)).toList();
    _upcoming = occ.where((o) => !o.isBefore(today)).toList();
    final pastIds =
        _past.map((o) => DateFormat('yyyy-MM-dd').format(o)).toList();
    _att = getIt<CircleRepository>()
        .getWeekAttendance(circleId: widget.circle.id, dateIds: pastIds);
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
    final fmt = DateFormat('EEEE d MMMM • h:mm a', 'ar');
    return FutureBuilder<Map<String, Map<String, AttendanceState>>>(
      future: _att,
      builder: (context, snap) {
        final att = snap.data ?? const {};
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
          children: [
            if (widget.onAddExtra != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: OutlinedButton.icon(
                    onPressed: widget.onAddExtra,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('جلسة استثنائية'),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              child: Text('القادمة', style: theme.textTheme.titleSmall),
            ),
            if (_upcoming.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('لا جلسات قادمة',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              )
            else
              for (final o in _upcoming.take(8))
                _row(theme, fmt, o, today: _isToday(o)),
            if (_past.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text('السجل', style: theme.textTheme.titleSmall),
              ),
              for (final o in _past.reversed.take(8))
                _row(theme, fmt, o,
                    past: true,
                    done: (att[DateFormat('yyyy-MM-dd').format(o)]
                            ?.isNotEmpty ??
                        false)),
            ],
          ],
        );
      },
    );
  }

  Widget _row(ThemeData theme, DateFormat fmt, DateTime o,
      {bool today = false, bool past = false, bool done = false}) {
    late Color color;
    late String label;
    late IconData icon;
    if (past) {
      color = done ? AppColors.success : AppColors.error;
      label = done ? 'منتهية' : 'فائتة';
      icon = done ? Icons.check_circle : Icons.cancel;
    } else if (today) {
      color = AppColors.primary;
      label = 'اليوم';
      icon = Icons.calendar_today;
    } else {
      color = AppColors.textMuted;
      label = 'قادمة';
      icon = Icons.event_outlined;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: today ? AppColors.primary : AppColors.border,
          width: today ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: past ? color : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(fmt.format(o), style: theme.textTheme.bodyMedium),
          ),
          if (today && widget.canManage)
            FilledButton.icon(
              onPressed: () => _startToday(o),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('بدء'),
              style:
                  FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
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
  late Set<String> _days = {...widget.initialDays};
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
        width: double.maxFinite,
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
                  activeColor: AppColors.primary,
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
  bool _weekly = false;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('اليوم')),
                      ButtonSegment(value: true, label: Text('الأسبوع')),
                    ],
                    selected: {_weekly},
                    onSelectionChanged: (s) =>
                        setState(() => _weekly = s.first),
                  ),
                ),
              ),
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Text('لا توجد طالبات بعد',
                            style: Theme.of(context).textTheme.bodyMedium),
                      )
                    : _weekly
                        ? _WeeklyAttendance(
                            circle: widget.circle,
                            students: students,
                            canManage: widget.canManage,
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

class _StudentsTable extends StatelessWidget {
  final Circle circle;
  final List<CircleMember> students;
  final void Function(CircleMember)? onEdit;
  const _StudentsTable(
      {required this.circle, required this.students, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = {for (final s in students) s.uid: s.name};
    Widget head(String t, int flex) => Expanded(
          flex: flex,
          child: Text(t,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  head('الطالبة', 3),
                  head('تسميع اليوم', 2),
                  head('تقدّم الحفظ', 3),
                  head('التقييم', 2),
                  head('الشريكة', 2),
                  head('إجراءات', 1),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final m = students[i];
                  return _StudentRow(
                    circle: circle,
                    member: m,
                    onEdit: onEdit,
                    partnerName:
                        m.partnerId == null ? null : names[m.partnerId],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentRow extends StatefulWidget {
  final Circle circle;
  final CircleMember member;
  final void Function(CircleMember)? onEdit;
  final String? partnerName;
  const _StudentRow({
    required this.circle,
    required this.member,
    required this.onEdit,
    this.partnerName,
  });

  @override
  State<_StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<_StudentRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;
    final initial = member.name.isNotEmpty ? member.name.characters.first : '؟';
    final last = member.lastRecitationAt;
    final pending = member.status == MemberStatus.pending;
    final partner = widget.partnerName;

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
                            if (member.juz != null)
                              Text('جزء ${member.juz}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // تسميع اليوم (الحضور + وقت آخر تسميع)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      pending
                          ? const StatusChip(
                              label: 'بانتظار', color: AppColors.warning)
                          : StatusChip(
                              label: member.attendance?.arabicLabel ?? '—',
                              color: attendanceColor(member.attendance),
                            ),
                      if (last != null) ...[
                        const SizedBox(height: 2),
                        Text(DateFormat('d/M h:mm', 'ar').format(last),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ],
                  ),
                ),
                // تقدّم الحفظ
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${member.memorizedPercent}%',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: member.memorizedRatio,
                            minHeight: 6,
                            backgroundColor: AppColors.sky,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // التقييم
                Expanded(
                  flex: 2,
                  child: StatusChip(
                    label: member.performance?.arabicLabel ?? 'بلا تقييم',
                    color: performanceColor(member.performance),
                  ),
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
          _StudentDetail(
              circle: widget.circle, member: member, partnerName: partner),
      ],
    );
  }
}

/// Expandable per-student detail panel under a table row.
/// Shows the fields available today; weekly attendance, streak, exam history
/// and contact will plug in once that data is modelled.
class _StudentDetail extends StatefulWidget {
  final Circle circle;
  final CircleMember member;
  final String? partnerName;
  const _StudentDetail(
      {required this.circle, required this.member, required this.partnerName});

  @override
  State<_StudentDetail> createState() => _StudentDetailState();
}

class _StudentDetailState extends State<_StudentDetail> {
  int? _pct;
  bool _loadingPct = true;

  @override
  void initState() {
    super.initState();
    _loadAttendancePercent();
  }

  /// Attendance % over the last 4 weeks of the circle's meeting days.
  Future<void> _loadAttendancePercent() async {
    try {
      final circle = widget.circle;
      final days = circle.days.isNotEmpty ? circle.days : _scheduleDayOrder;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final daysSinceSat = (today.weekday - DateTime.saturday) % 7;
      final thisWeekStart = today.subtract(Duration(days: daysSinceSat));
      final dateIds = <String>[];
      for (var w = 0; w < 4; w++) {
        final ws = thisWeekStart.subtract(Duration(days: 7 * w));
        for (final d in days) {
          final idx = _scheduleDayOrder.indexOf(d);
          if (idx < 0) continue;
          final date = ws.add(Duration(days: idx));
          if (!date.isAfter(today)) {
            dateIds.add(DateFormat('yyyy-MM-dd').format(date));
          }
        }
      }
      final data = await getIt<CircleRepository>()
          .getWeekAttendance(circleId: circle.id, dateIds: dateIds);
      var recorded = 0, present = 0;
      for (final id in dateIds) {
        final st = data[id]?[widget.member.uid];
        if (st != null) {
          recorded++;
          if (st == AttendanceState.present || st == AttendanceState.late_) {
            present++;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _pct = recorded == 0 ? null : (present / recorded * 100).round();
        _loadingPct = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPct = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;
    final last = member.lastRecitationAt;
    final partner = (widget.partnerName == null || widget.partnerName!.isEmpty)
        ? '—'
        : widget.partnerName!;
    final pctLabel = _loadingPct ? '…' : (_pct == null ? '—' : '$_pct%');
    final items = <(IconData, String, String)>[
      (Icons.menu_book_outlined, 'الجزء', member.juz?.toString() ?? '—'),
      (
        Icons.event_available_outlined,
        'حالة الحضور',
        member.attendance?.arabicLabel ?? '—'
      ),
      (Icons.percent_outlined, 'نسبة الحضور (٤ أسابيع)', pctLabel),
      (
        Icons.mic_none_outlined,
        'آخر تسميع',
        last == null ? 'لم تُسمّع' : DateFormat('EEEE d/M h:mm', 'ar').format(last)
      ),
      (
        Icons.auto_stories_outlined,
        'الصفحات المحفوظة',
        '${member.memorizedPages}/${member.totalPages}'
      ),
      (Icons.people_alt_outlined, 'الشريكة (تلاوة متبادلة)', partner),
      (
        Icons.contact_phone_outlined,
        'جهة الاتصال',
        (member.contact == null || member.contact!.isEmpty)
            ? '—'
            : member.contact!
      ),
      (
        Icons.sticky_note_2_outlined,
        'ملاحظات',
        (member.notes == null || member.notes!.isEmpty) ? '—' : member.notes!
      ),
    ];
    return Container(
      width: double.infinity,
      color: AppColors.beige,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          for (final it in items)
            SizedBox(
              width: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(it.$1, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.$2,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted, fontSize: 10)),
                        Text(it.$3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall),
                      ],
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

// ---------------------------------------------------------------------------
//  Weekly attendance grid (students × meeting days)
// ---------------------------------------------------------------------------

class _WeeklyAttendance extends StatefulWidget {
  final Circle circle;
  final List<CircleMember> students;
  final bool canManage;
  const _WeeklyAttendance({
    required this.circle,
    required this.students,
    required this.canManage,
  });

  @override
  State<_WeeklyAttendance> createState() => _WeeklyAttendanceState();
}

class _WeeklyAttendanceState extends State<_WeeklyAttendance> {
  late DateTime _thisWeekStart; // Saturday of the current week
  late DateTime _weekStart; // Saturday of the displayed week
  List<String> _codes = const [];
  List<String> _dateIds = const [];
  Future<Map<String, Map<String, AttendanceState>>>? _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceSat = (today.weekday - DateTime.saturday) % 7;
    _thisWeekStart = today.subtract(Duration(days: daysSinceSat));
    _weekStart = _thisWeekStart;
    _initCodes();
  }

  /// Meeting days come from the حلقة's fixed rule (single source of truth,
  /// same as the «أيام الحلقة» card). Falls back to deriving from sessions for
  /// circles with no rule yet, then to the full week.
  Future<void> _initCodes() async {
    List<String> codes;
    if (widget.circle.days.isNotEmpty) {
      codes = [
        for (final c in _scheduleDayOrder)
          if (widget.circle.days.contains(c)) c,
      ];
    } else {
      try {
        final sessions =
            await getIt<CalendarRepository>().getSessions(widget.circle.id);
        final wds = sessions.map((s) => s.scheduledAt.weekday).toSet();
        codes = [
          for (final c in _scheduleDayOrder)
            if (wds.contains(_codeToWeekday[c])) c,
        ];
      } catch (_) {
        codes = const [];
      }
    }
    if (codes.isEmpty) codes = List.of(_scheduleDayOrder);
    if (!mounted) return;
    setState(() {
      _codes = codes;
      _recompute();
    });
  }

  /// Rebuild the visible date ids from [_weekStart] and reload the week.
  void _recompute() {
    _dateIds = [
      for (final c in _codes)
        DateFormat('yyyy-MM-dd').format(
            _weekStart.add(Duration(days: _scheduleDayOrder.indexOf(c)))),
    ];
    _future = _load();
  }

  bool get _isCurrentWeek => !_weekStart.isBefore(_thisWeekStart);

  /// Move by [delta] weeks (−1 = previous). Never navigate into the future.
  void _changeWeek(int delta) {
    final next = _weekStart.add(Duration(days: delta * 7));
    if (next.isAfter(_thisWeekStart)) return;
    setState(() {
      _weekStart = next;
      _recompute();
    });
  }

  Future<Map<String, Map<String, AttendanceState>>> _load() =>
      getIt<CircleRepository>()
          .getWeekAttendance(circleId: widget.circle.id, dateIds: _dateIds);

  AttendanceState? _nextState(AttendanceState? s) {
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

  Future<void> _cycle(
      String dateId, String uid, AttendanceState? current) async {
    try {
      await getIt<CircleRepository>().markAttendance(
        circleId: widget.circle.id,
        dateId: dateId,
        uid: uid,
        state: _nextState(current),
      );
      if (mounted) setState(() => _future = _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('تعذّر حفظ الحضور — تحقّقي من نشر قواعد Firestore')));
      }
    }
  }

  Widget _weekNavBar(ThemeData theme) {
    final end = _weekStart.add(const Duration(days: 6));
    final label =
        '${DateFormat('d MMM', 'ar').format(_weekStart)} – ${DateFormat('d MMM', 'ar').format(end)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'الأسبوع السابق',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeWeek(-1),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.titleSmall),
              if (_isCurrentWeek)
                Text('هذا الأسبوع',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'الأسبوع التالي',
            icon: const Icon(Icons.chevron_left),
            onPressed: _isCurrentWeek ? null : () => _changeWeek(1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _weekNavBar(theme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _legend(theme),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _future == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<Map<String, Map<String, AttendanceState>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snap.data!;
                    final codes = _codes;
                    final dateIds = _dateIds;
                    Widget head(String t, int flex, {bool center = false}) =>
                        Expanded(
                          flex: flex,
                          child: Text(t,
                              textAlign:
                                  center ? TextAlign.center : TextAlign.start,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted)),
                        );
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
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
                                  for (final c in codes)
                                    head(_scheduleDayLabels[c] ?? c, 2,
                                        center: true),
                                  head('النسبة', 2, center: true),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.separated(
                                itemCount: widget.students.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final m = widget.students[i];
                                  var recorded = 0, attended = 0;
                                  final cells = <Widget>[];
                                  for (var j = 0; j < codes.length; j++) {
                                    final dateId = dateIds[j];
                                    final st = data[dateId]?[m.uid];
                                    if (st != null) {
                                      recorded++;
                                      if (st == AttendanceState.present ||
                                          st == AttendanceState.late_) {
                                        attended++;
                                      }
                                    }
                                    cells.add(Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: _AttCell(
                                          state: st,
                                          onTap: widget.canManage
                                              ? () => _cycle(dateId, m.uid, st)
                                              : null,
                                        ),
                                      ),
                                    ));
                                  }
                                  final pct = recorded == 0
                                      ? 0
                                      : (attended / recorded * 100).round();
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 3,
                                            child: _nameCell(theme, m)),
                                        ...cells,
                                        Expanded(
                                            flex: 2,
                                            child:
                                                Center(child: _pctChip(pct))),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _nameCell(ThemeData theme, CircleMember m) {
    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.sky,
          child: Text(m.name.isNotEmpty ? m.name.characters.first : '؟',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }

  Widget _pctChip(int pct) {
    final color = pct >= 75
        ? AppColors.success
        : (pct >= 50 ? AppColors.warning : AppColors.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text('$pct٪',
          style:
              TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _legend(ThemeData theme) {
    Widget item(IconData ic, Color c, String t) => Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, size: 14, color: c),
            const SizedBox(width: 4),
            Text(t,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(children: [
        item(Icons.check_circle, AppColors.success, 'حاضرة'),
        item(Icons.cancel, AppColors.error, 'غائبة'),
        item(Icons.remove_circle, AppColors.warning, 'معذورة'),
        Text('— لا جلسة',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted)),
      ]),
    );
  }
}

class _AttCell extends StatelessWidget {
  final AttendanceState? state;
  final VoidCallback? onTap;
  const _AttCell({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData? ic;
    Color color;
    switch (state) {
      case AttendanceState.present:
        ic = Icons.check_circle;
        color = AppColors.success;
        break;
      case AttendanceState.absent:
        ic = Icons.cancel;
        color = AppColors.error;
        break;
      case AttendanceState.excused:
        ic = Icons.remove_circle;
        color = AppColors.warning;
        break;
      case AttendanceState.late_:
        ic = Icons.schedule;
        color = AppColors.warning;
        break;
      case null:
        ic = null;
        color = AppColors.textMuted;
        break;
    }
    final child = ic == null
        ? Text('—', style: TextStyle(color: color))
        : Icon(ic, size: 20, color: color);
    if (onTap == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(4), child: child),
    );
  }
}
