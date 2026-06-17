import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/model /ui_state.dart';
import '../bloc/auth_bloc.dart';

/// Phone (OTP) sign-in (US-01): enter phone -> receive SMS code -> verify.
class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدخول عبر الهاتف')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == UIStatus.error) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state.status == UIStatus.success && state.user != null) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
        builder: (context, state) {
          final loading = state.status == UIStatus.loading;
          final codeStep = state.otpSent;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      codeStep ? 'أدخلي رمز التحقق المرسَل برسالة' : 'أدخلي رقم هاتفك',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (!codeStep)
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '+9665XXXXXXXX',
                        ),
                      )
                    else
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'رمز التحقق',
                          prefixIcon: Icon(Icons.sms_outlined),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () {
                              final bloc = context.read<AuthBloc>();
                              if (codeStep) {
                                bloc.add(AuthOtpVerified(_code.text.trim()));
                              } else {
                                bloc.add(AuthPhoneOtpRequested(_phone.text.trim()));
                              }
                            },
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(codeStep ? 'تأكيد' : 'إرسال الرمز'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
