import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 900 && user != null) {
        // Web: reuse the exact same (proven) content list inside the rail
        // shell, capped to a comfortable reading width.
        return WebShell(
          user: user,
          current: 'المساعدة',
          breadcrumb: 'المساعدة والدعم',
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _list(padding: const EdgeInsets.all(24)),
            ),
          ),
        );
      }
      return _mobile();
    });
  }

  // ----------------------------- mobile -----------------------------

  Widget _mobile() {
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
                child: _list(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28))),
          ],
        ),
      ),
    );
  }

  // ------------------------- shared content -------------------------

  Widget _list({required EdgeInsets padding}) {
    final topics = HelpContent.popular
        .where((a) => _query.isEmpty || a.question.contains(_query))
        .toList();
    return ListView(
      padding: padding,
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
