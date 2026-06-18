import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../calendar/pages/manage_calendar_page.dart';
import '../../exam/pages/teacher_exams_page.dart';
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
class CircleWorkspacePage extends StatelessWidget {
  final Circle circle;
  final AppUser user;

  const CircleWorkspacePage({super.key, required this.circle, required this.user});

  bool get _canManage =>
      user.role == UserRole.teacher || user.role == UserRole.supervisor;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 48, title: const SizedBox.shrink()),
        body: Column(
          children: [
            _CircleHeader(circle: circle, canManage: _canManage),
            Material(
              color: AppColors.surface,
              child: const TabBar(
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'الطالبات'),
                  Tab(text: 'الجدول'),
                  Tab(text: 'الجلسات'),
                  Tab(text: 'الاختبارات'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _StudentsTab(circle: circle, canManage: _canManage),
                  _ScheduleTab(
                      circle: circle, user: user, canManage: _canManage),
                  _LinkTab(
                    icon: Icons.podcasts_outlined,
                    label: 'الجلسات المباشرة',
                    buttonText: 'فتح الجلسات',
                    onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            LiveSessionPage(circleId: circle.id, user: user))),
                  ),
                  _LinkTab(
                    icon: Icons.assignment_outlined,
                    label: 'اختبارات الحلقة',
                    buttonText: 'فتح الاختبارات',
                    onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => TeacherExamsPage(
                            circleId: circle.id, user: user))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Hero header (breadcrumb + title + count + info cards + invite code)
// ---------------------------------------------------------------------------

class _CircleHeader extends StatelessWidget {
  final Circle circle;
  final bool canManage;
  const _CircleHeader({required this.circle, required this.canManage});

  String get _daysLabel {
    final ordered =
        _scheduleDayOrder.where((d) => circle.dayTimes.containsKey(d)).toList();
    final src = ordered.isNotEmpty ? ordered : circle.days;
    if (src.isEmpty) return 'لم تُحدَّد';
    return src.map((d) => _scheduleDayLabels[d] ?? d).join(' · ');
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
        Text(circle.name,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        _MemberCount(circleId: circle.id),
      ],
    );

    final cards = <Widget>[
      _InfoCard(
          icon: Icons.person_outline,
          label: 'المعلم المسؤول',
          value: circle.teacherName.isEmpty ? '—' : circle.teacherName),
      _InfoCard(
          icon: Icons.event_outlined, label: 'أيام الحلقة', value: _daysLabel),
      _InfoCard(
          icon: Icons.menu_book_outlined,
          label: 'مستوى الحلقة',
          value: circle.level.isEmpty ? '—' : circle.level),
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

class _LinkTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String buttonText;
  final VoidCallback onOpen;

  const _LinkTab({
    required this.icon,
    required this.label,
    required this.buttonText,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(minimumSize: const Size(220, 48)),
            ),
          ],
        ),
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

class _ScheduleTab extends StatefulWidget {
  final Circle circle;
  final AppUser user;
  final bool canManage;
  const _ScheduleTab(
      {required this.circle, required this.user, required this.canManage});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  late final Map<String, String> _times = {...widget.circle.dayTimes};
  late int _duration = widget.circle.durationMinutes;
  bool _saving = false;

  Future<void> _pickTime(String day) async {
    final current = _times[day];
    final init = current != null
        ? TimeOfDay(
            hour: int.parse(current.split(':')[0]),
            minute: int.parse(current.split(':')[1]))
        : const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      setState(() => _times[day] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  void _toggle(String day) => setState(() {
        if (_times.containsKey(day)) {
          _times.remove(day);
        } else {
          _times[day] = '08:00';
        }
      });

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<CircleRepository>().updateSchedule(
        circleId: widget.circle.id,
        dayTimes: _times,
        durationMinutes: _duration,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ الجدول الأسبوعي')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّر الحفظ: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.canManage) {
      final entries = _scheduleDayOrder.where(_times.containsKey).toList();
      return entries.isEmpty
          ? Center(
              child: Text('لم يُحدَّد جدول الحلقة بعد',
                  style: theme.textTheme.bodyMedium))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final d in entries)
                  ListTile(
                    leading:
                        const Icon(Icons.event_outlined, color: AppColors.primary),
                    title: Text(_scheduleDayLabels[d]!),
                    trailing: Text('${_times[d]} · $_duration د',
                        style: theme.textTheme.titleSmall),
                  ),
              ],
            );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('أيام ومواعيد الحلقة', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('اختاري أيام اللقاء ووقت كل يوم — يظهر تلقائيًا في الجدول الأسبوعي.',
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.md),
        for (final d in _scheduleDayOrder)
          _DayRow(
            label: _scheduleDayLabels[d]!,
            selected: _times.containsKey(d),
            time: _times[d],
            onToggle: () => _toggle(d),
            onPickTime: () => _pickTime(d),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('مدة اللقاء', style: theme.textTheme.titleSmall),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: _duration,
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                DropdownMenuItem(value: 45, child: Text('45 دقيقة')),
                DropdownMenuItem(value: 60, child: Text('60 دقيقة')),
                DropdownMenuItem(value: 90, child: Text('90 دقيقة')),
              ],
              onChanged: (v) => setState(() => _duration = v ?? 60),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: const Text('حفظ الجدول'),
        ),
        const Divider(height: AppSpacing.xl),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ManageCalendarPage(
                  circleId: widget.circle.id, user: widget.user))),
          icon: const Icon(Icons.add),
          label: const Text('إضافة جلسة فردية (مرة واحدة)'),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final bool selected;
  final String? time;
  final VoidCallback onToggle;
  final VoidCallback onPickTime;
  const _DayRow({
    required this.label,
    required this.selected,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.sky : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: CheckboxListTile(
              value: selected,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(label),
            ),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.access_time, size: 16),
                label: Text(time ?? 'الوقت'),
              ),
            ),
        ],
      ),
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
                              students: students, onEdit: onEdit);
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md, 4, AppSpacing.md, 24),
                          itemCount: students.length,
                          itemBuilder: (context, i) => _StudentCard(
                            member: students[i],
                            canManage: widget.canManage,
                            onTap: onEdit == null
                                ? null
                                : () => onEdit(students[i]),
                          ),
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
  final VoidCallback? onTap;

  const _StudentCard(
      {required this.member, required this.canManage, this.onTap});

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

  void _save({bool recite = false}) {
    widget.bloc.add(CircleMemberUpdated(
      circleId: widget.circleId,
      uid: widget.member.uid,
      attendance: _attendance,
      performance: _performance,
      memorizedPages: _pages,
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
  final List<CircleMember> students;
  final void Function(CircleMember)? onEdit;
  const _StudentsTable({required this.students, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  head('الحضور', 2),
                  head('آخر تسميع', 2),
                  head('تقدّم الحفظ', 3),
                  head('الحالة', 2),
                  if (onEdit != null) head('إجراءات', 1),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) =>
                    _StudentRow(member: students[i], onEdit: onEdit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final CircleMember member;
  final void Function(CircleMember)? onEdit;
  const _StudentRow({required this.member, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = member.name.isNotEmpty ? member.name.characters.first : '؟';
    final last = member.lastRecitationAt;
    final pending = member.status == MemberStatus.pending;

    return InkWell(
      onTap: onEdit == null ? null : () => onEdit!(member),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
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
            Expanded(
              flex: 2,
              child: pending
                  ? const StatusChip(
                      label: 'بانتظار', color: AppColors.warning)
                  : StatusChip(
                      label: member.attendance?.arabicLabel ?? '—',
                      color: attendanceColor(member.attendance),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                last == null
                    ? 'لم تُسمّع'
                    : DateFormat('d/M h:mm', 'ar').format(last),
                style: theme.textTheme.bodySmall,
              ),
            ),
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
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: StatusChip(
                label: member.performance?.arabicLabel ?? 'بلا تقييم',
                color: performanceColor(member.performance),
              ),
            ),
            if (onEdit != null)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.primary),
                    onPressed: () => onEdit!(member),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
