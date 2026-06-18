import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../profile/pages/profile_theme.dart';
import 'help_data.dart';

/// تواصل مع الدعم — pick an inquiry type, write a message, send via email.
class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  InquiryType _type = InquiryType.technical;
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('يرجى كتابة رسالتك')));
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: HelpContent.supportEmail,
      query: 'subject=${Uri.encodeComponent('[${_type.label}] دعم وصال')}'
          '&body=${Uri.encodeComponent(text)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text('تعذّر فتح البريد. راسلنا على ${HelpContent.supportEmail}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text('تواصل مع الدعم',
                        textAlign: TextAlign.center,
                        style: ProfileTheme.appBarTitle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: ProfileTheme.ink),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('اختر نوع الاستفسار'),
                    const SizedBox(height: 10),
                    for (final t in InquiryType.values) ...[
                      _TypeRow(
                        type: t,
                        selected: _type == t,
                        onTap: () => setState(() => _type = t),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                    _label('اكتب رسالتك'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _message,
                      maxLines: 5,
                      decoration: ProfileTheme.field(
                          'اكتب وصفاً لمشكلتك أو استفسارك...'),
                    ),
                    const SizedBox(height: 18),
                    _label('إرفاق ملف (اختياري)'),
                    const SizedBox(height: 10),
                    DottedAttachBox(onTap: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            content: Text(
                                'أرفق الملف مباشرة في تطبيق البريد بعد الضغط على إرسال')));
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ProfileTheme.primaryButton,
                      onPressed: _send,
                      child: const Text('إرسال'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(t, style: ProfileTheme.label),
      );
}

class _TypeRow extends StatelessWidget {
  const _TypeRow(
      {required this.type, required this.selected, required this.onTap});
  final InquiryType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? ProfileTheme.green : ProfileTheme.border,
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(type.icon,
                size: 22,
                color: selected ? ProfileTheme.green : ProfileTheme.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(type.label,
                  style: TextStyle(
                      color: ProfileTheme.ink,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600)),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? ProfileTheme.green : ProfileTheme.border,
            ),
          ],
        ),
      ),
    );
  }
}

class DottedAttachBox extends StatelessWidget {
  const DottedAttachBox({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ProfileTheme.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined,
                size: 20, color: ProfileTheme.muted),
            SizedBox(width: 8),
            Text('اختر ملف',
                style: TextStyle(
                    color: ProfileTheme.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
