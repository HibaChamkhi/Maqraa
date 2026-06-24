import 'package:flutter/material.dart';

import '../../../core/ui/styles/theme.dart';

/// Global help / FAQ hub (المساعدة).
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faqs = <(String, String)>[
    (
      'كيف أنشئ حلقة جديدة؟',
      'من قائمة «الحلقات» اضغطي «إنشاء حلقة جديدة»، ثم أدخلي الاسم والنوع والخصوصية.'
    ),
    (
      'كيف أضيف طالبة إلى حلقة؟',
      'افتحي الحلقة من «الحلقات»، ثم من تبويب «الطالبات» اضغطي زر الإضافة، أو شاركي رمز الانضمام.'
    ),
    (
      'هل بيانات كل حلقة منفصلة؟',
      'نعم، لكل حلقة طالباتها وحضورها وتقدّمها بشكل مستقل تمامًا عن باقي الحلقات.'
    ),
    (
      'كيف أتابع تقدّم الطالبات؟',
      'من «التقارير» اختاري الحلقة لعرض متابعة التسليم اليومي ونسب الحفظ.'
    ),
    (
      'كيف أفعّل التذكير اليومي؟',
      'من «الإعدادات» ← «التذكير اليومي» فعّلي الإشعار واختاري الوقت المناسب.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('المساعدة')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent_outlined,
                    color: AppColors.primary, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'الأسئلة الشائعة حول استخدام «وِصَال». لم تجدي إجابتك؟ تواصلي معنا.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (final f in _faqs)
                  ExpansionTile(
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.textMuted,
                    title: Text(f.$1, style: theme.textTheme.titleSmall),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$2,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('support@wisal.app')),
            ),
            icon: const Icon(Icons.mail_outline),
            label: const Text('تواصلي مع الدعم'),
          ),
        ],
      ),
    );
  }
}
