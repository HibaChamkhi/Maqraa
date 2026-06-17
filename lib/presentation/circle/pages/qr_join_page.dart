import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../bloc/circle_bloc.dart';
import 'circle_info_page.dart';

/// US-29: scan a QR code that encodes a circle invite code, then join.
class QrJoinPage extends StatelessWidget {
  final AppUser user;

  const QrJoinPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CircleBloc>(),
      child: _QrJoinView(user: user),
    );
  }
}

class _QrJoinView extends StatefulWidget {
  final AppUser user;

  const _QrJoinView({required this.user});

  @override
  State<_QrJoinView> createState() => _QrJoinViewState();
}

class _QrJoinViewState extends State<_QrJoinView> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BuildContext context, BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
    if (raw == null) return;
    _handled = true;
    context.read<CircleBloc>().add(CircleJoinByCodeRequested(raw.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('مسح رمز QR')),
      body: BlocConsumer<CircleBloc, CircleState>(
        listenWhen: (prev, curr) =>
            curr.status == UIStatus.error ||
            (curr.actionDone && curr.circle != null),
        listener: (context, state) {
          if (state.status == UIStatus.error) {
            _handled = false; // allow re-scan after a failure
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state.actionDone && state.circle != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CircleInfoPage(circleId: state.circle!.id),
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state.status == UIStatus.loading;
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) => _onDetect(context, capture),
              ),
              // Aiming frame.
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.xl,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    loading
                        ? 'جارٍ الانضمام...'
                        : 'وجّهي الكاميرا نحو رمز QR الخاص بالحلقة',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              if (loading)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
