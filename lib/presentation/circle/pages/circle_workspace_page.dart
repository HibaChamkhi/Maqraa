import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
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
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(circle.name),
              Text(
                [if (circle.level.isNotEmpty) circle.level].join(),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'الطالبات'),
              Tab(text: 'الجدول'),
              Tab(text: 'الجلسات'),
              Tab(text: 'الاختبارات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StudentsTab(circle: circle, canManage: _canManage),
            _LinkTab(
              icon: Icons.calendar_month_outlined,
              label: 'جدول الجلسات الأسبوعي',
              buttonText: 'فتح التقويم',
              onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ManageCalendarPage(circleId: circle.id, user: user))),
            ),
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
                  builder: (_) =>
                      TeacherExamsPage(circleId: circle.id, user: user))),
            ),
          ],
        ),
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
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: () => _addStudent(context),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('إضافة طالبة'),
            )
          : null,
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

          final activeCount =
              students.where((m) => m.status == MemberStatus.active).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'ابحثي عن طالبة...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Text('$activeCount طالبة',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Text('لا توجد طالبات بعد',
                            style: Theme.of(context).textTheme.bodyMedium),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 4, AppSpacing.md, 90),
                        itemCount: students.length,
                        itemBuilder: (context, i) => _StudentCard(
                          member: students[i],
                          canManage: widget.canManage,
                          onTap: widget.canManage
                              ? () => _editStudent(context, students[i])
                              : null,
                        ),
                      ),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة طالبة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الطالبة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: juzController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الجزء (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إضافة')),
        ],
      ),
    );
    if (ok == true && nameController.text.trim().isNotEmpty) {
      bloc.add(CircleStudentAdded(
        circleId: widget.circle.id,
        name: nameController.text,
        juz: int.tryParse(juzController.text.trim()),
      ));
    }
  }

  void _editStudent(BuildContext context, CircleMember member) {
    final bloc = context.read<CircleBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StudentEditor(
        circleId: widget.circle.id,
        member: member,
        bloc: bloc,
      ),
    );
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
