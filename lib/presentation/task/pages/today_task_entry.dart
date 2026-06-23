import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import 'today_task_page.dart';

/// Drawer entry for «واجب اليوم»: the side menu only knows the [user], so this
/// resolves the student's circle first, then opens [TodayTaskPage]. If the
/// student is in several circles it shows a quick picker.
class TodayTaskEntryPage extends StatefulWidget {
  final AppUser user;

  const TodayTaskEntryPage({super.key, required this.user});

  @override
  State<TodayTaskEntryPage> createState() => _TodayTaskEntryPageState();
}

class _TodayTaskEntryPageState extends State<TodayTaskEntryPage> {
  late Future<List<Circle>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<CircleRepository>().getMyCircles();
  }

  void _open(String circleId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TodayTaskPage(circleId: circleId, user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E9),
      appBar: AppBar(title: const Text('واجب اليوم')),
      body: FutureBuilder<List<Circle>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final circles = snap.data ?? const <Circle>[];
          if (snap.hasError) {
            return _message(
              Icons.error_outline,
              'تعذّر تحميل حلقاتك',
              'تحقّقي من الاتصال وحاولي مرة أخرى.',
            );
          }
          if (circles.isEmpty) {
            return _message(
              Icons.groups_2_outlined,
              'لست في أي حلقة بعد',
              'انضمي إلى حلقة لتظهر لك واجبات اليوم.',
            );
          }
          // Single circle → open directly after the first frame.
          if (circles.length == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _open(circles.first.id);
            });
            return const Center(child: CircularProgressIndicator());
          }
          // Multiple circles → let her choose.
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text('اختاري الحلقة',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
              ),
              for (final c in circles)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1A0F6B5B),
                      child: Icon(Icons.groups_2_outlined,
                          color: AppColors.primary),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _open(c.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _message(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
