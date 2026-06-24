import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/session/models/session.dart';
import '../bloc/calendar_bloc.dart';

/// US-30: teacher/supervisor manages session appointments in a calendar
/// (add/edit/delete sessions with date + time).
class ManageCalendarPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const ManageCalendarPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CalendarBloc>()..add(CalendarSessionsRequested(circleId)),
      child: _ManageCalendarView(circleId: circleId),
    );
  }
}

class _ManageCalendarView extends StatefulWidget {
  final String circleId;

  const _ManageCalendarView({required this.circleId});

  @override
  State<_ManageCalendarView> createState() => _ManageCalendarViewState();
}

class _ManageCalendarViewState extends State<_ManageCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Session> _sessionsOn(List<Session> all, DateTime day) =>
      all.where((s) => _isSameDay(s.scheduledAt, day)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('تقويم الجلسات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('جلسة جديدة'),
      ),
      body: BlocConsumer<CalendarBloc, CalendarState>(
        listenWhen: (prev, curr) => curr.message.isNotEmpty && curr.actionDone,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final daySessions = _sessionsOn(state.sessions, _selectedDay);
          return Column(
            children: [
              Card(
                child: TableCalendar<Session>(
                  locale: 'ar',
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => _isSameDay(d, _selectedDay),
                  eventLoader: (d) => _sessionsOn(state.sessions, d),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: daySessions.isEmpty
                    ? Center(
                        child: Text('لا توجد جلسات في هذا اليوم',
                            style: theme.textTheme.bodyMedium),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        itemCount: daySessions.length,
                        itemBuilder: (context, i) {
                          final s = daySessions[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.event_outlined),
                              title: Text(s.title),
                              subtitle: Text(
                                  '${timeFormat.format(s.scheduledAt)} • ${s.status.arabicLabel}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _openEditor(context, session: s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.error),
                                    onPressed: () => context
                                        .read<CalendarBloc>()
                                        .add(CalendarSessionDeleted(
                                          circleId: widget.circleId,
                                          sessionId: s.id,
                                        )),
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
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Session? session}) async {
    final bloc = context.read<CalendarBloc>();
    final result = await showModalBottomSheet<_SessionFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SessionForm(
        initial: session,
        initialDay: _selectedDay,
      ),
    );
    if (result == null) return;
    if (session == null) {
      bloc.add(CalendarSessionAdded(
        circleId: widget.circleId,
        title: result.title,
        scheduledAt: result.scheduledAt,
        link: result.link,
      ));
    } else {
      bloc.add(CalendarSessionUpdated(
        circleId: widget.circleId,
        sessionId: session.id,
        title: result.title,
        scheduledAt: result.scheduledAt,
        link: result.link,
      ));
    }
  }
}

class _SessionFormResult {
  final String title;
  final DateTime scheduledAt;
  final String link;

  const _SessionFormResult({
    required this.title,
    required this.scheduledAt,
    required this.link,
  });
}

class _SessionForm extends StatefulWidget {
  final Session? initial;
  final DateTime initialDay;

  const _SessionForm({this.initial, required this.initialDay});

  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _linkController;
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _linkController = TextEditingController(text: initial?.link ?? '');
    final base = initial?.scheduledAt ?? widget.initialDay;
    _date = DateTime(base.year, base.month, base.day);
    _time = TimeOfDay.fromDateTime(initial?.scheduledAt ?? DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    Navigator.of(context).pop(_SessionFormResult(
      title: _titleController.text.trim(),
      scheduledAt: scheduledAt,
      link: _linkController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM y', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');
    final timeAsDate =
        DateTime(0, 1, 1, _time.hour, _time.minute);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.initial == null ? 'جلسة جديدة' : 'تعديل الجلسة',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الجلسة',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'يرجى إدخال عنوان الجلسة'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(dateFormat.format(_date)),
              trailing: TextButton(
                  onPressed: _pickDate, child: const Text('تغيير')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(timeFormat.format(timeAsDate)),
              trailing: TextButton(
                  onPressed: _pickTime, child: const Text('تغيير')),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'رابط الجلسة (اختياري)',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
