import 'package:flutter/material.dart';

import '../profile/pages/profile_theme.dart';
import 'help_data.dart';

/// مقال المساعدة — a single help article (steps + tip + helpful vote).
class HelpArticlePage extends StatelessWidget {
  const HelpArticlePage({super.key, required this.article});

  final HelpArticle article;

  void _thanks(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('شكراً لتقييمك!')));
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
                    child: Text('مقال المساعدة',
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
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: ProfileTheme.greenSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_outline,
                            color: ProfileTheme.green, size: 34),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(article.question,
                        textAlign: TextAlign.center,
                        style: ProfileTheme.name.copyWith(fontSize: 20)),
                    const SizedBox(height: 12),
                    Text(article.intro,
                        textAlign: TextAlign.center, style: ProfileTheme.hint),
                    const SizedBox(height: 20),
                    for (var i = 0; i < article.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}.',
                                style: const TextStyle(
                                    color: ProfileTheme.green,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(article.steps[i],
                                  style: const TextStyle(
                                      color: ProfileTheme.ink,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    if (article.tip != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF1DF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('نصيحة',
                                style: TextStyle(
                                    color: Color(0xFFB9821B),
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(article.tip!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xFF8A6A2A), height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text('هل كان هذا المقال مفيداً؟',
                        style: ProfileTheme.label),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _VoteButton(
                            icon: Icons.thumb_down_alt_outlined,
                            onTap: () => _thanks(context)),
                        const SizedBox(width: 16),
                        _VoteButton(
                            icon: Icons.thumb_up_alt_outlined,
                            onTap: () => _thanks(context)),
                      ],
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
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ProfileTheme.border),
        ),
        child: Icon(icon, color: ProfileTheme.muted),
      ),
    );
  }
}
