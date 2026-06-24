import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/auth/models/app_user.dart';
import '../auth/bloc/auth_bloc.dart';
import '../profile/pages/profile_theme.dart';
import '../profile/pages/web_shell.dart';
import 'contact_support_page.dart';
import 'help_article_page.dart';
import 'help_data.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String _query = '';

  void _openArticle(HelpArticle a) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => HelpArticlePage(article: a)));

  void _openContact() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ContactSupportPage()));

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 900 && user != null) return _web(user);
      return _mobile();
    });
  }

  // ----------------------------- mobile -----------------------------

  Widget _mobile() {
    final topics = HelpContent.popular
        .where((a) => _query.isEmpty || a.question.contains(_query))
        .toList();
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
                    child: Text('المساعدة والدعم',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: ProfileTheme.field('ابحث عن موضوع للمساعدة',
                        prefix: const Icon(Icons.search,
                            size: 20, color: ProfileTheme.muted)),
                  ),
                  const SizedBox(height: 22),
                  Text('الموضوعات الشائعة', style: ProfileTheme.sectionTitle),
                  const SizedBox(height: 12),
                  for (final a in topics)
                    _TopicRow(title: a.question, onTap: () => _openArticle(a)),
                  if (_query.isEmpty)
                    _TopicRow(
                        title: 'عرض جميع الموضوعات',
                        onTap: () => _openArticle(HelpContent.popular.first)),
                  const SizedBox(height: 22),
                  Text('تواصل معنا', style: ProfileTheme.sectionTitle),
                  const SizedBox(height: 12),
                  _ContactCard(
                    icon: Icons.mail_outline,
                    title: 'راسل الدعم الفني',
                    subtitle: 'نرد عليك في أقرب وقت ممكن',
                    onTap: _openContact,
                  ),
                  const SizedBox(height: 10),
                  _ContactCard(
                    icon: Icons.live_help_outlined,
                    title: 'الأسئلة الشائعة',
                    subtitle: 'إجابات على أكثر الأسئلة شيوعاً',
                    onTap: () => _openArticle(HelpContent.popular.first),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------- web -----------------------------

  Widget _web(AppUser user) {
    final topics = HelpContent.teacherTopics
        .where((t) =>
            _query.isEmpty ||
            t.title.contains(_query) ||
            t.subtitle.contains(_query))
        .toList();
    return WebShell(
      user: user,
      current: 'المساعدة والدعم',
      breadcrumb: 'المساعدة والدعم',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('المساعدة والدعم', style: ProfileTheme.sectionTitle),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: ProfileTheme.field('ابحث عن موضوع للمساعدة...',
                prefix: const Icon(Icons.search,
                    size: 20, color: ProfileTheme.muted)),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, c) {
            final contact = _ContactPanel(
              onSupport: _openContact,
              onCall: () => _launch(Uri(
                  scheme: 'tel', path: HelpContent.supportPhone)),
              onEmail: () => _launch(
                  Uri(scheme: 'mailto', path: HelpContent.supportEmail)),
            );
            final grid = _TopicsGrid(topics: topics, onOpen: _openArticle);
            if (c.maxWidth >= 760) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: contact),
                    const SizedBox(width: 16),
                    Expanded(child: grid),
                  ],
                ),
              );
            }
            return Column(
              children: [grid, const SizedBox(height: 16), contact],
            );
          }),
          const SizedBox(height: 20),
          _CreateTicketBar(onCreate: _openContact),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ProfileTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                          color: ProfileTheme.ink,
                          fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.chevron_left, color: ProfileTheme.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ProfileTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: ProfileTheme.ink,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: ProfileTheme.hint),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: ProfileTheme.greenSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: ProfileTheme.green, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicsGrid extends StatelessWidget {
  const _TopicsGrid({required this.topics, required this.onOpen});
  final List<HelpTopic> topics;
  final void Function(HelpArticle) onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ProfileTheme.cardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('الموضوعات الشائعة', style: ProfileTheme.sectionTitle),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 520 ? 2 : 1;
            final w = (c.maxWidth - (cols - 1) * 14) / cols;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final t in topics)
                  SizedBox(
                    width: w,
                    child: _TopicCard(topic: t, onTap: () => onOpen(t.article)),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.onTap});
  final HelpTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ProfileTheme.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ProfileTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title,
                      style: const TextStyle(
                          color: ProfileTheme.ink,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(topic.subtitle,
                      style: ProfileTheme.hint, maxLines: 2),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: topic.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(topic.icon, color: topic.color, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactPanel extends StatelessWidget {
  const _ContactPanel(
      {required this.onSupport, required this.onCall, required this.onEmail});
  final VoidCallback onSupport;
  final VoidCallback onCall;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ProfileTheme.cardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تواصل معنا', style: ProfileTheme.sectionTitle),
          const SizedBox(height: 16),
          _Row(
            icon: Icons.mail_outline,
            title: 'راسل الدعم الفني',
            value: 'نرد عليك في أقرب وقت ممكن',
            onTap: onSupport,
          ),
          const SizedBox(height: 12),
          _Row(
            icon: Icons.phone_outlined,
            title: 'اتصل بنا',
            value: '${HelpContent.supportPhoneDisplay}\n${HelpContent.phoneHours}',
            onTap: onCall,
          ),
          const SizedBox(height: 12),
          _Row(
            icon: Icons.alternate_email_outlined,
            title: 'البريد الإلكتروني',
            value: '${HelpContent.supportEmail}\n${HelpContent.emailSla}',
            onTap: onEmail,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ProfileTheme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ProfileTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: ProfileTheme.ink,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(value, style: ProfileTheme.hint),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: ProfileTheme.greenSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ProfileTheme.green, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTicketBar extends StatelessWidget {
  const _CreateTicketBar({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ProfileTheme.cardShadow,
      child: Row(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileTheme.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onCreate,
            child: const Text('إنشاء تذكرة دعم جديدة'),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('لم تجد ما تبحث عنه؟', style: ProfileTheme.label),
              const SizedBox(height: 2),
              Text('فريق الدعم جاهز لمساعدتك', style: ProfileTheme.hint),
            ],
          ),
        ],
      ),
    );
  }
}
