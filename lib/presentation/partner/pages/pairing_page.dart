import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../bloc/partner_bloc.dart';

/// US-16: teacher/supervisor pairs students as recitation partners —
/// either manually (pick two active students) or auto-pairs everyone two-by-two.
///
/// [members] is the circle's member list (passed in from the members screen so
/// we don't reach into the circle feature's data source).
class PairingPage extends StatelessWidget {
  final String circleId;
  final AppUser user;
  final List<CircleMember> members;

  const PairingPage({
    super.key,
    required this.circleId,
    required this.user,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PartnerBloc>()..add(PartnerPairsRequested(circleId)),
      child: _PairingView(circleId: circleId, members: members),
    );
  }
}

class _PairingView extends StatefulWidget {
  final String circleId;
  final List<CircleMember> members;

  const _PairingView({required this.circleId, required this.members});

  @override
  State<_PairingView> createState() => _PairingViewState();
}

class _PairingViewState extends State<_PairingView> {
  CircleMember? _a;
  CircleMember? _b;

  List<CircleMember> get _students => widget.members
      .where((m) =>
          m.role == UserRole.student && m.status == MemberStatus.active)
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final students = _students;
    return Scaffold(
      appBar: AppBar(title: const Text('إقران الرفيقات')),
      body: BlocConsumer<PartnerBloc, PartnerState>(
        listenWhen: (p, c) => c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('إقران يدوي', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _MemberDropdown(
                label: 'الطالبة الأولى',
                value: _a,
                items: students.where((m) => m.uid != _b?.uid).toList(),
                onChanged: (v) => setState(() => _a = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MemberDropdown(
                label: 'الطالبة الثانية',
                value: _b,
                items: students.where((m) => m.uid != _a?.uid).toList(),
                onChanged: (v) => setState(() => _b = v),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('إقران الاثنتين'),
                onPressed: (_a != null && _b != null)
                    ? () => context.read<PartnerBloc>().add(
                          PartnerManualPairRequested(
                            circleId: widget.circleId,
                            a: _a!,
                            b: _b!,
                          ),
                        )
                    : null,
              ),
              const Divider(height: AppSpacing.xl),
              Text('إقران تلقائي', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'يُقرن جميع الطالبات النشطات اثنتين اثنتين (يُعيد توزيع الثنائيات الحالية).',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.shuffle),
                label: const Text('إقران تلقائي للجميع'),
                onPressed: () => context
                    .read<PartnerBloc>()
                    .add(PartnerAutoPairRequested(widget.circleId)),
              ),
              const Divider(height: AppSpacing.xl),
              Text('الثنائيات الحالية', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (state.status == UIStatus.loading && state.pairs.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (state.pairs.isEmpty)
                Text('لا توجد ثنائيات بعد', style: theme.textTheme.bodyMedium)
              else
                ...state.pairs.map(
                  (p) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.people_alt_outlined),
                      title: Text('${p.aName}  —  ${p.bName}'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberDropdown extends StatelessWidget {
  final String label;
  final CircleMember? value;
  final List<CircleMember> items;
  final ValueChanged<CircleMember?> onChanged;

  const _MemberDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CircleMember>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
