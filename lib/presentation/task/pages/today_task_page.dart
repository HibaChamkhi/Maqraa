import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';
import '../../../domain/partner/models/partner.dart';
import '../../../domain/partner/repositories/partner_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../../../domain/task/models/daily_task.dart';
import '../../notification/pages/notifications_page.dart';
import '../../partner/pages/my_partner_page.dart';
import '../bloc/task_bloc.dart';

const Color _green = AppColors.primary; // أخضر رئيسي #0F6B5B
const Color _bg = Color(0xFFF6F2E9); // بيج
const Color _amber = AppColors.warning;

/// US-08/09: redesigned «واجب اليوم» — the student sees today's task, records
/// the memorization, follows the partner-confirmation status, and gets a quick
/// look at the next session and the next exam.
class TodayTaskPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const TodayTaskPage({super.key, required this.circleId, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskBloc>()
        ..add(TaskTodayLoadRequested(circleId: circleId, uid: user.uid)),
      child: _TodayTaskView(circleId: circleId, user: user),
    );
  }
}

class _TodayTaskView extends StatefulWidget {
  final String circleId;
  final AppUser user;

  const _TodayTaskView({required this.circleId, required this.user});

  @override
  State<_TodayTaskView> createState() => _TodayTaskViewState();
}

class _TodayTaskViewState extends State<_TodayTaskView> {
  Pair? _pair;
  bool _pairLoading = true;
  Session? _nextSession;
  bool _sessionLoading = true;
  Exam? _nextExam;
  bool _examLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartner();
    _loadNextSession();
    _loadNextExam();
  }

  Future<void> _loadPartner() async {
    try {
      final p = await getIt<PartnerRepository>().getMyPair(widget.circleId);
      if (mounted) setState(() => _pair = p);
    } catch (_) {
      // best-effort
    } finally {
      if (mounted) setState(() => _pairLoading = false);
    }
  }

  Future<void> _loadNextSession() async {
    try {
      final list = await getIt<SessionRepository>().getSessions(widget.circleId);
      final now = DateTime.now();
      final upcoming = list
          .where((s) =>
              s.scheduledAt.isAfter(now) && s.status != SessionStatus.ended)
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      if (mounted) {
        setState(() => _nextSession = upcoming.isEmpty ? null : upcoming.first);
      }
    } catch (_) {
      // best-effort
    } finally {
      if (mounted) setState(() => _sessionLoading = false);
    }
  }

  Future<void> _loadNextExam() async {
    try {
      final list = await getIt<ExamRepository>().getExams(widget.circleId);
      final now = DateTime.now();
      final upcoming = list.where((e) => e.date.isAfter(now)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (mounted) {
        setState(() => _nextExam = upcoming.isEmpty ? null : upcoming.first);
      }
    } catch (_) {
      // best-effort
    } finally {
      if (mounted) setState(() => _examLoading = false);
    }
  }

  String? get _partnerId {
    final p = _pair;
    if (p == null) return null;
    return p.aId == widget.user.uid ? p.bId : p.aId;
  }

  String? get _partnerName {
    final p = _pair;
    if (p == null) return null;
    final name = p.aId == widget.user.uid ? p.bName : p.aName;
    return name.trim().isEmpty ? null : name.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack:
                  Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null,
              onBell: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
            ),
            Expanded(
              child: BlocConsumer<TaskBloc, TaskState>(
                listenWhen: (p, c) =>
                    p.message != c.message && c.message.isNotEmpty,
                listener: (context, state) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                },
                builder: (context, state) {
                  if (state.status == UIStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _DateHeader(),
                            const SizedBox(height: 18),
                            _TaskCard(
                              task: state.todayTask,
                              onRecord: () => _onRecord(state),
                            ),
                            const SizedBox(height: 22),
                            _SectionLabel(
                              icon: Icons.record_voice_over_outlined,
                              text: 'حالة التسميع',
                            ),
                            const SizedBox(height: 10),
                            _RecitationCard(
                              loading: _pairLoading,
                              partnerName: _partnerName,
                              task: state.todayTask,
                              onContact: _partnerName == null
                                  ? null
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => MyPartnerPage(
                                            circleId: widget.circleId,
                                            user: widget.user,
                                          ),
                                        ),
                                      ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _NextSessionCard(
                                    loading: _sessionLoading,
                                    session: _nextSession,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _NextExamCard(
                                    loading: _examLoading,
                                    exam: _nextExam,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  void _onRecord(TaskState state) {
    final task = state.todayTask;
    if (task == null) return;
    final known = _partnerId;
    if (known != null && known.isNotEmpty) {
      context.read<TaskBloc>().add(
            TaskConfirmationRequested(
              circleId: widget.circleId,
              dateId: state.dateId,
              task: task,
              partnerId: known,
            ),
          );
      return;
    }
    _askConfirmation(context, state, task);
  }

  void _askConfirmation(BuildContext context, TaskState state, DailyTask task) {
    final controller = TextEditingController(text: task.partnerId ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('طلب تأكيد الرفيقة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخلي معرّف الرفيقة (uid) التي ستؤكّد تسميعك:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'معرّف الرفيقة',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final partnerId = controller.text.trim();
              if (partnerId.isEmpty) return;
              context.read<TaskBloc>().add(
                    TaskConfirmationRequested(
                      circleId: widget.circleId,
                      dateId: state.dateId,
                      task: task,
                      partnerId: partnerId,
                    ),
                  );
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── top bar ─────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback onBell;

  const _TopBar({this.onBack, required this.onBell});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          if (onBack != null)
            _RoundIcon(icon: Icons.arrow_back_ios_new, onTap: onBack!)
          else
            const SizedBox(width: 42),
          const Spacer(),
          const Text(
            'واجب اليوم',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          _RoundIcon(icon: Icons.notifications_none_rounded, onTap: onBell),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: _green),
        ),
      ),
    );
  }
}

// ───────────────────────── date header ─────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greg = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);
    final hijri = _hijriToday();
    return Column(
      children: [
        Text(
          greg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        if (hijri.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            hijri,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  static String _hijriToday() {
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.now();
      return '${_arDigits(h.toFormat("dd MMMM yyyy"))} هـ';
    } catch (_) {
      return '';
    }
  }
}

String _arDigits(String s) {
  const w = '0123456789';
  const a = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = w.indexOf(ch);
    b.write(i == -1 ? ch : a[i]);
  }
  return b.toString();
}

// ───────────────────────── task card ─────────────────────────

class _TaskCard extends StatelessWidget {
  final DailyTask? task;
  final VoidCallback onRecord;

  const _TaskCard({required this.task, required this.onRecord});

  @override
  Widget build(BuildContext context) {
    final t = task;
    if (t == null) {
      return _whiteCard(
        child: Column(
          children: const [
            Icon(Icons.event_available_outlined,
                size: 46, color: AppColors.textMuted),
            SizedBox(height: 10),
            Text('لا يوجد واجب مسجّل لليوم',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            SizedBox(height: 4),
            Text('ستجدين واجبك هنا فور إسناده من معلّمتك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    final parts = _splitRange(t.range);
    final surah = parts.$1.isEmpty ? 'الواجب المطلوب' : parts.$1;
    final ayah = parts.$2;
    final done = t.status == TaskStatus.done;

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: _green, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المقطع المطلوب حفظه',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                    const SizedBox(height: 3),
                    Text(surah,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        )),
                  ],
                ),
              ),
            ],
          ),
          if (ayah.isNotEmpty || (t.note != null && t.note!.isNotEmpty)) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ayah.isNotEmpty)
                  _pill(Icons.format_list_numbered_rtl,
                      'الآيات ${_arDigits(ayah)}'),
                if (t.note != null && t.note!.isNotEmpty)
                  _pill(Icons.sticky_note_2_outlined, t.note!),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          _statusRow(t, done),
          const SizedBox(height: 16),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded,
                      color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text('تم الحفظ وأكّدته الرفيقة',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5)),
                ],
              ),
            )
          else
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                    t.awaitingConfirmation
                        ? Icons.refresh_rounded
                        : Icons.check_circle_outline,
                    size: 21),
                label: Text(
                  t.awaitingConfirmation
                      ? 'إعادة إرسال طلب التأكيد'
                      : 'سجّلت الحفظ',
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          if (!done) ...[
            const SizedBox(height: 8),
            Text(
              t.awaitingConfirmation
                  ? 'بانتظار أن تؤكّد رفيقتك تسميعك'
                  : 'بعد الحفظ، اطلبي من رفيقتك تأكيد تسميعك',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusRow(DailyTask t, bool done) {
    final Color c;
    final IconData icon;
    final String label;
    if (done) {
      c = AppColors.success;
      icon = Icons.verified_outlined;
      label = 'منجز';
    } else if (t.awaitingConfirmation) {
      c = _amber;
      icon = Icons.hourglass_top_rounded;
      label = 'بانتظار التأكيد';
    } else {
      c = AppColors.textMuted;
      icon = Icons.schedule_rounded;
      label = 'لم يتم بعد';
    }
    return Row(
      children: [
        const Text('حالة الواجب',
            style: TextStyle(
                fontSize: 13.5,
                color: AppColors.ink,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13.5, color: c, fontWeight: FontWeight.w700)),
      ],
    );
  }

  static Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _green),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: _green,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Splits a free-text range like «سورة الملك ١-١٠» into (surah, ayah).
(String, String) _splitRange(String raw) {
  final r = raw.trim();
  if (r.isEmpty) return ('', '');
  final m = RegExp(r'([\d٠-٩][\d٠-٩\s\-–—,]*)$').firstMatch(r);
  if (m != null) {
    final ayah = m.group(0)!.trim();
    final surah = r.substring(0, m.start).trim();
    if (surah.isNotEmpty) return (surah, ayah);
  }
  return (r, '');
}

// ───────────────────────── recitation card ─────────────────────────

class _RecitationCard extends StatelessWidget {
  final bool loading;
  final String? partnerName;
  final DailyTask? task;
  final VoidCallback? onContact;

  const _RecitationCard({
    required this.loading,
    required this.partnerName,
    required this.task,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _whiteCard(
        child: const SizedBox(
          height: 36,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ),
      );
    }
    if (partnerName == null) {
      return _whiteCard(
        child: Row(
          children: const [
            Icon(Icons.person_off_outlined, color: AppColors.textMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text('لم يتم تعيين رفيقة للتسميع بعد',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
            ),
          ],
        ),
      );
    }

    final t = task;
    final Color c;
    final String status;
    if (t != null && t.status == TaskStatus.done) {
      c = AppColors.success;
      status = 'أكّدت تسميعك';
    } else if (t != null && t.awaitingConfirmation) {
      c = _amber;
      status = 'بانتظار تأكيد الرفيقة';
    } else {
      c = AppColors.textMuted;
      status = 'لم يبدأ التسميع بعد';
    }

    return _whiteCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: _green.withValues(alpha: 0.12),
                child: Text(
                  partnerName!.trim().substring(0, 1),
                  style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الرفيقة',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(partnerName!,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration:
                                BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(status,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: c,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onContact,
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: BorderSide(color: _green.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
              label: const Text('تواصل معها',
                  style:
                      TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── next session / exam ─────────────────────────

class _NextSessionCard extends StatelessWidget {
  final bool loading;
  final Session? session;

  const _NextSessionCard({required this.loading, required this.session});

  @override
  Widget build(BuildContext context) {
    final s = session;
    final String value;
    final String sub;
    if (loading) {
      value = '…';
      sub = '';
    } else if (s == null) {
      value = 'لا توجد جلسة قادمة';
      sub = '';
    } else {
      value = DateFormat('EEEE', 'ar').format(s.scheduledAt);
      sub =
          '${DateFormat('d MMM', 'ar').format(s.scheduledAt)} • ${DateFormat('h:mm a', 'ar').format(s.scheduledAt)}';
    }
    return _miniCard(
      icon: Icons.videocam_outlined,
      title: 'الجلسة القادمة',
      value: value,
      sub: sub,
    );
  }
}

class _NextExamCard extends StatelessWidget {
  final bool loading;
  final Exam? exam;

  const _NextExamCard({required this.loading, required this.exam});

  @override
  Widget build(BuildContext context) {
    final e = exam;
    final String value;
    final String sub;
    if (loading) {
      value = '…';
      sub = '';
    } else if (e == null) {
      value = 'لا يوجد اختبار قادم';
      sub = '';
    } else {
      value = e.title.trim().isEmpty ? 'اختبار' : e.title.trim();
      final days = e.date.difference(DateTime.now()).inDays;
      final when = DateFormat('d MMM', 'ar').format(e.date);
      sub = days <= 0 ? when : '$when • بعد ${_arDigits('$days')} يوم';
    }
    return _miniCard(
      icon: Icons.assignment_outlined,
      title: 'الاختبار القادم',
      value: value,
      sub: sub,
    );
  }
}

Widget _miniCard({
  required IconData icon,
  required String title,
  required String value,
  required String sub,
}) {
  return _whiteCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: _green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ],
    ),
  );
}

// ───────────────────────── shared bits ─────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _green),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
      ],
    );
  }
}

Widget _whiteCard({required Widget child, EdgeInsets? padding}) {
  return Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}
