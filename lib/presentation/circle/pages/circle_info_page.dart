import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/centered_content.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../bloc/circle_bloc.dart';
import 'circle_members_page.dart';
import 'join_requests_page.dart';

/// Circle info screen.
/// - US-29: shows the invite code as a QR (for joining by scan).
/// - US-38: privacy toggle (public / private) — owner only.
/// - Entry points to members (US-05) and pending requests (US-41).
///
/// [user] is the current user; pass it so the members page can gate management
/// (e.g. promotion) and so privacy/requests controls are shown only to the
/// teacher or a supervisor of this circle.
class CircleInfoPage extends StatelessWidget {
  final String circleId;
  final AppUser? user;

  const CircleInfoPage({super.key, required this.circleId, this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CircleBloc>()..add(CircleLoadRequested(circleId)),
      child: _CircleInfoView(circleId: circleId, user: user),
    );
  }
}

class _CircleInfoView extends StatelessWidget {
  final String circleId;
  final AppUser? user;

  const _CircleInfoView({required this.circleId, this.user});

  bool _canManage(Circle circle) {
    final u = user;
    if (u == null) return false;
    return circle.teacherId == u.uid || circle.supervisorIds.contains(u.uid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات الحلقة')),
      body: BlocConsumer<CircleBloc, CircleState>(
        listenWhen: (prev, curr) =>
            curr.status == UIStatus.error || curr.message.isNotEmpty,
        listener: (context, state) {
          if (state.message.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final circle = state.circle;
          if (circle == null) {
            if (state.status == UIStatus.error) {
              return Center(
                child: Text(state.message, style: theme.textTheme.bodyMedium),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final canManage = _canManage(circle);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CenteredContent(
              maxWidth: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(circle.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),
                  _QrCard(inviteCode: circle.inviteCode),
                  const SizedBox(height: AppSpacing.lg),
                  if (canManage) ...[
                    _PrivacyCard(circle: circle, circleId: circleId),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: const Text('أعضاء الحلقة'),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CircleMembersPage(
                                circleId: circleId,
                                user: user ??
                                    AppUser(
                                      uid: '',
                                      name: '',
                                      email: '',
                                      role: UserRole.student,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        if (canManage) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.how_to_reg_outlined),
                            title: const Text('طلبات الانضمام'),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    JoinRequestsPage(circleId: circleId),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final String inviteCode;

  const _QrCard({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text('رمز الدعوة', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: QrImageView(
                data: inviteCode,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              inviteCode,
              style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                      const SnackBar(content: Text('تم نسخ الرمز')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('نسخ الرمز'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final Circle circle;
  final String circleId;

  const _PrivacyCard({required this.circle, required this.circleId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublic = circle.privacy == Privacy.public;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: SwitchListTile(
          title: const Text('حلقة عامة'),
          subtitle: Text(
            isPublic
                ? 'يمكن للطالبات اكتشافها وإرسال طلب انضمام'
                : 'الانضمام عبر رمز الدعوة فقط',
            style: theme.textTheme.bodySmall,
          ),
          value: isPublic,
          onChanged: (value) => context.read<CircleBloc>().add(
                CirclePrivacyChanged(
                  circleId: circleId,
                  privacy: value ? Privacy.public : Privacy.private,
                ),
              ),
        ),
      ),
    );
  }
}
