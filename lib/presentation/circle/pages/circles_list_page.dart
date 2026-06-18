import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'create_circle_page.dart';
import 'join_circle_page.dart';
import 'qr_join_page.dart';
import 'circle_workspace_page.dart';

/// الحلقات — all circles the current user belongs to. Teachers tap a حلقة to
/// open its workspace; students see theirs. This is the entry to the
/// circle-scoped flow.
class CirclesListPage extends StatefulWidget {
  const CirclesListPage({super.key});

  @override
  State<CirclesListPage> createState() => _CirclesListPageState();
}

class _CirclesListPageState extends State<CirclesListPage> {
  late Future<List<Circle>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<CircleRepository>().getMyCircles();
  }

  void _reload() =>
      setState(() => _future = getIt<CircleRepository>().getMyCircles());

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    final isTeacher = user?.role == UserRole.teacher;

    return Scaffold(
      appBar: AppBar(title: const Text('الحلقات')),
      body: FutureBuilder<List<Circle>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final circles = snap.data ?? const [];
          if (circles.isEmpty) {
            return _empty(context, user);
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              for (final c in circles) _circleCard(context, c, user),
              const SizedBox(height: AppSpacing.sm),
              if (isTeacher)
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CreateCirclePage()));
                    _reload();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إنشاء حلقة جديدة'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _circleCard(BuildContext context, Circle c, AppUser? user) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: user == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CircleWorkspacePage(circle: c, user: user),
                )),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.groups_2_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (c.level.isNotEmpty) c.level,
                        c.gender == Gender.female ? 'بنات' : 'بنين',
                        c.privacy.arabicLabel,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, AppUser? user) {
    final isTeacher = user?.role == UserRole.teacher;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_2_outlined,
                size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(isTeacher ? 'لا توجد حلقة بعد' : 'لم تنضمّي إلى حلقة بعد',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            if (isTeacher)
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CreateCirclePage()));
                  _reload();
                },
                icon: const Icon(Icons.add),
                label: const Text('إنشاء حلقة'),
              )
            else if (user != null) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => JoinCirclePage(user: user)));
                  _reload();
                },
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('الانضمام برمز دعوة'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => QrJoinPage(user: user)));
                  _reload();
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('الانضمام بمسح QR'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
