import 'package:flutter/material.dart';

/// Static help content (no backend / CMS). Edit here to add or change articles.
class HelpArticle {
  final String question;
  final String intro;
  final List<String> steps;
  final String? tip;

  const HelpArticle({
    required this.question,
    required this.intro,
    required this.steps,
    this.tip,
  });
}

/// A web topic card (icon + title + subtitle) that opens an [article].
class HelpTopic {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final HelpArticle article;

  const HelpTopic({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.article,
  });
}

class HelpContent {
  HelpContent._();

  // --- contact ---
  static const supportEmail = 'support@wardapp.com';
  static const supportPhone = '+966123456789';
  static const supportPhoneDisplay = '+966 12 345 6789';
  static const phoneHours = 'من الأحد إلى الخميس ٨ ص - ٦ م';
  static const emailSla = 'نرد خلال ٢٤ ساعة';

  // --- student / mobile popular topics ---
  static const List<HelpArticle> popular = [
    HelpArticle(
      question: 'كيف أسجل دخولي؟',
      intro: 'لتسجيل الدخول إلى حسابك اتبع الخطوات التالية:',
      steps: [
        'افتح التطبيق واضغط على «تسجيل الدخول».',
        'أدخل بريدك الإلكتروني أو رقم جوالك.',
        'أدخل كلمة المرور ثم اضغط «دخول».',
        'إن نسيت كلمة المرور اضغط «نسيت كلمة المرور؟».',
      ],
      tip: 'تأكد من صحة البريد وكلمة المرور وأن اتصالك بالإنترنت فعّال.',
    ),
    HelpArticle(
      question: 'كيف أتابع دروسي؟',
      intro: 'يمكنك متابعة دروسك بسهولة من خلال الخطوات التالية:',
      steps: [
        'من الصفحة الرئيسية، اضغط على جدول الدروس.',
        'اختر اليوم والحلقة التي تريدها.',
        'اضغط على «الانضمام الآن».',
        'ستنتقل إلى غرفة الحلقة مباشرة.',
      ],
      tip: 'تأكد من اتصالك بالإنترنت قبل بدء الحلقة بوقت كافٍ.',
    ),
    HelpArticle(
      question: 'كيف أرفع واجب؟',
      intro: 'لرفع واجبك إلى المعلّم اتبع الخطوات التالية:',
      steps: [
        'افتح «واجب اليوم» من الصفحة الرئيسية.',
        'سجّل تلاوتك أو اكتب ما طُلب منك.',
        'اضغط «تسليم» لإرسال الواجب.',
        'ستظهر حالة الواجب «بانتظار التأكيد».',
      ],
      tip: 'يمكنك مراجعة واجباتك السابقة من قسم «مهامي».',
    ),
    HelpArticle(
      question: 'كيف أراجع تقاريري؟',
      intro: 'لمتابعة تقدّمك وتقاريرك:',
      steps: [
        'افتح قسم «تقدّمي» من القائمة.',
        'استعرض نسبة الحفظ والإنجاز.',
        'اطّلع على سلسلة الالتزام والأوسمة.',
      ],
      tip: 'حافظ على إنجاز يومي لرفع سلسلة الالتزام.',
    ),
    HelpArticle(
      question: 'كيف أغيّر كلمة المرور؟',
      intro: 'لتغيير كلمة المرور بأمان:',
      steps: [
        'افتح «الإعدادات» ثم «تغيير كلمة المرور».',
        'أدخل كلمة المرور الحالية.',
        'أدخل كلمة المرور الجديدة وأكّدها.',
        'اضغط «تحديث كلمة المرور».',
      ],
      tip: 'اختر كلمة مرور قوية تجمع بين أحرف وأرقام.',
    ),
  ];

  // --- teacher / web topic grid ---
  static const List<HelpTopic> teacherTopics = [
    HelpTopic(
      title: 'إدارة الحلقات',
      subtitle: 'تعرف على كيفية إنشاء وإدارة الحلقات',
      icon: Icons.calendar_month_outlined,
      color: Color(0xFF3B82A0),
      article: HelpArticle(
        question: 'إدارة الحلقات',
        intro: 'لإنشاء وإدارة حلقاتك:',
        steps: [
          'من لوحة التحكم اضغط «إنشاء حلقة».',
          'أدخل اسم الحلقة وخصوصيتها.',
          'شارك رمز الدعوة مع الطالبات.',
          'تابعي الطلبات والأعضاء من «الطالبات».',
        ],
        tip: 'يمكنك ترقية طالبة إلى مشرفة لمساعدتك في الإدارة.',
      ),
    ),
    HelpTopic(
      title: 'إدارة الطلاب',
      subtitle: 'كيفية إضافة الطلاب وإدارتهم',
      icon: Icons.group_outlined,
      color: Color(0xFFF59E0B),
      article: HelpArticle(
        question: 'إدارة الطلاب',
        intro: 'لإدارة طلاب حلقتك:',
        steps: [
          'افتحي «الطالبات» من القائمة.',
          'راجعي طلبات الانضمام واقبليها.',
          'تابعي تسليمات وحضور كل طالبة.',
        ],
        tip: 'استخدمي «متابعة التسليم» لمعرفة من سلّم اليوم.',
      ),
    ),
    HelpTopic(
      title: 'التقارير والإحصائيات',
      subtitle: 'فهم التقارير وقراءة الإحصائيات',
      icon: Icons.insert_chart_outlined,
      color: Color(0xFF7C5CD6),
      article: HelpArticle(
        question: 'التقارير والإحصائيات',
        intro: 'لقراءة تقارير حلقتك:',
        steps: [
          'افتحي قسم «التقارير».',
          'استعرضي متوسط الحضور والتقدم.',
          'صدّري التقرير الأسبوعي عند الحاجة.',
        ],
      ),
    ),
    HelpTopic(
      title: 'النظام والإعدادات',
      subtitle: 'إعدادات الحساب والنظام',
      icon: Icons.settings_outlined,
      color: Color(0xFF2E7D52),
      article: HelpArticle(
        question: 'النظام والإعدادات',
        intro: 'لضبط حسابك والنظام:',
        steps: [
          'افتحي «الإعدادات».',
          'حدّثي بياناتك الشخصية وكلمة المرور.',
          'تحكّمي في الإشعارات وتفضيلاتها.',
        ],
      ),
    ),
  ];
}

/// Inquiry types for the contact form.
enum InquiryType {
  technical('مشكلة تقنية', Icons.settings_suggest_outlined),
  general('استفسار عام', Icons.chat_bubble_outline),
  feedback('اقتراح أو ملاحظات', Icons.lightbulb_outline),
  other('أخرى', Icons.more_horiz);

  final String label;
  final IconData icon;
  const InquiryType(this.label, this.icon);
}
