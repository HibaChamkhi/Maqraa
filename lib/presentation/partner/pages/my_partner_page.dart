import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/partner/models/partner.dart';
import '../bloc/partner_bloc.dart';

/// US-17: a student sees their assigned partner and a daily-call organizer.
/// US-34: book recitation appointments and see pending/confirmed ones.
class MyPartnerPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const MyPartnerPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PartnerBloc>()
        ..add(PartnerMyPairRequested(circleId))
        ..add(PartnerAppointmentsRequested(circleId)),
      child: _MyPartnerView(circleId: circleId, user: user),
    );
  }
}

class _MyPartnerView extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const _MyPartnerView({required this.circleId, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('رفيقتي')),
      body: BlocConsumer<PartnerBloc, PartnerState>(
        listenWhen: (p, c) => c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.myPair == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final pair = state.myPair;
          final partnerName = pair?.partnerNameFor(user.uid);
          final partnerId = pair?.partnerIdFor(user.uid);
          if (pair == null || partnerName == null || partnerId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'لم يتم إسناد رفيقة لكِ بعد. تواصلي مع المعلّمة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      partnerName.isNotEmpty
                          ? partnerName.characters.first
                          : '؟',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                  title: Text(partnerName, style: theme.textTheme.titleMedium),
                  subtitle: const Text('رفيقتك في المراجعة'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: SwitchListTile(
                  title: const Text('المكالمة اليومية تمّت اليوم'),
                  subtitle: Text(DateFormat('EEEE، d MMMM', 'ar')
                      .format(DateTime.now())),
                  value: state.dailyCallDone,
                  onChanged: (v) => context.read<PartnerBloc>().add(
                        PartnerDailyCallToggled(circleId: circleId, done: v),
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('المواعيد', style: theme.textTheme.titleMedium),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('حجز موعد'),
                    onPressed: () => _bookDialog(
                      context,
                      circleId: circleId,
                      toId: partnerId,
                      toName: partnerName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.appointments.isEmpty)
                Text('لا توجد مواعيد بعد', style: theme.textTheme.bodyMedium)
              else
                ...state.appointments.map(
                  (a) => _AppointmentTile(
                    appointment: a,
                    myUid: user.uid,
                    onConfirm: () => context.read<PartnerBloc>().add(
                          PartnerAppointmentConfirmed(
                            circleId: circleId,
                            appointmentId: a.id,
                          ),
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _bookDialog(
    BuildContext context, {
    required String circleId,
    required String toId,
    required String toName,
  }) async {
    final bloc = context.read<PartnerBloc>();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final when = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    bloc.add(PartnerAppointmentBooked(
      circleId: circleId,
      toId: toId,
      toName: toName,
      time: when,
    ));
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final String myUid;
  final VoidCallback onConfirm;

  const _AppointmentTile({
    required this.appointment,
    required this.myUid,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEEE d MMM • h:mm a', 'ar');
    final iAmInvited = appointment.toId == myUid;
    final other =
        iAmInvited ? appointment.fromName : appointment.toName;
    return Card(
      child: ListTile(
        leading: Icon(
          appointment.confirmed
              ? Icons.event_available
              : Icons.event_busy_outlined,
          color: appointment.confirmed ? AppColors.success : AppColors.warning,
        ),
        title: Text(fmt.format(appointment.time)),
        subtitle: Text('مع $other'),
        trailing: appointment.confirmed
            ? Text('مؤكّد',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.success))
            : (iAmInvited
                ? TextButton(
                    onPressed: onConfirm,
                    child: const Text('تأكيد'),
                  )
                : Text('بانتظار التأكيد',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.warning))),
      ),
    );
  }
}
