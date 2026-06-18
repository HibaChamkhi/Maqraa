import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import 'circle_workspace_page.dart';

/// All students across every circle the teacher manages (the sidebar
/// «الطالبات» — app-wide, as opposed to the per-circle tab inside a حلقة).
class AllStudentsPage extends StatefulWidget {
  final AppUser user;
  const AllStudentsPage({super.key, required this.user});

  @override
  State<AllStudentsPage> createState() => _AllStudentsPageState();
}

typedef _Row = ({CircleMember member, Circle circle});

class _AllStudentsPageState extends State<AllStudentsPage> {
  final _repo = getIt<CircleRepository>();
  final List<StreamSubscription<List<CircleMember>>> _subs = [];
  final Map<String, Circle> _circleById = {};
  final Map<String, List<CircleMember>> _membersByCircle = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final circles = await _repo.getMyCircles();
      if (!mounted) return;
      if (circles.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      for (final c in circles) {
        _circleById[c.id] = c;
        _subs.add(_repo.membersStream(c.id).listen((members) {
          if (!mounted) return;
          setState(() {
            _membersByCircle[c.id] = members;
            _loading = false;
          });
        }, onError: (_) {
          if (mounted) setState(() => _loading = false);
        }));
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  List<_Row> _allRows() {
    final rows = <_Row>[];
    _membersByCircle.forEach((cid, members) {
      final c = _circleById[cid];
      if (c == null) return;
      for (final m in members.where((m) =>
          m.role == UserRole.student && m.status == MemberStatus.active)) {
        rows.add((member: m, circle: c));
      }
    });
    rows.sort((a, b) =>
        a.member.memorizedPercent.compareTo(b.member.memorizedPercent));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطالبات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Builder(builder: (context) {
              final all = _allRows();
              final rows = all
                  .where((r) => r.member.name.contains(_query.trim()))
                  .toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'بحث عن طالبة...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${all.length} طالبة',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    child: rows.isEmpty
                        ? Center(
                            child: Text('لا توجد طالبات بعد',
                                style: Theme.of(context).textTheme.bodyMedium))
                        : LayoutBuilder(builder: (context, c) {
                            void open(Circle circle) =>
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => CircleWorkspacePage(
                                      circle: circle, user: widget.user),
                                ));
                            if (c.maxWidth >= 720) {
                              return _AllTable(rows: rows, onOpen: open);
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                                  0, AppSpacing.md, AppSpacing.md),
                              itemCount: rows.length,
                              itemBuilder: (context, i) =>
                                  _StudentMiniCard(row: rows[i], onOpen: open),
                            );
                          }),
                  ),
                ],
              );
            }),
    );
  }
}

class _AllTable extends StatelessWidget {
  final List<_Row> rows;
  final void Function(Circle) onOpen;
  const _AllTable({required this.rows, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget head(String t, int flex) => Expanded(
        flex: flex,
        child: Text(t,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted)));
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                head('الطالبة', 3),
                head('الحلقة', 2),
                head('الحضور', 2),
                head('تقدّم الحفظ', 3),
                head('الحالة', 2),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  final m = r.member;
                  return InkWell(
                    onTap: () => onOpen(r.circle),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.sky,
                                child: Text(
                                    m.name.isNotEmpty
                                        ? m.name.characters.first
                                        : '؟',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall),
                                    if (m.juz != null)
                                      Text('جزء ${m.juz}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(r.circle.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall),
                          ),
                          Expanded(
                            flex: 2,
                            child: StatusChip(
                              label: m.attendance?.arabicLabel ?? '—',
                              color: attendanceColor(m.attendance),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${m.memorizedPercent}%',
                                      style: theme.textTheme.bodySmall),
                                  const SizedBox(height: 3),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: m.memorizedRatio,
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
                          Expanded(
                            flex: 2,
                            child: StatusChip(
                              label:
                                  m.performance?.arabicLabel ?? 'بلا تقييم',
                              color: performanceColor(m.performance),
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
        ),
      ),
    );
  }
}

class _StudentMiniCard extends StatelessWidget {
  final _Row row;
  final void Function(Circle) onOpen;
  const _StudentMiniCard({required this.row, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = row.member;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => onOpen(row.circle),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.sky,
                  child: Text(
                      m.name.isNotEmpty ? m.name.characters.first : '؟',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: theme.textTheme.titleMedium),
                      Text(row.circle.name,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                StatusChip(
                  label: m.attendance?.arabicLabel ?? '—',
                  color: attendanceColor(m.attendance),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: m.memorizedRatio,
                      minHeight: 7,
                      backgroundColor: AppColors.sky,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${m.memorizedPercent}%',
                    style: theme.textTheme.titleSmall),
                const SizedBox(width: 10),
                StatusChip(
                  label: m.performance?.arabicLabel ?? 'بلا تقييم',
                  color: performanceColor(m.performance),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
