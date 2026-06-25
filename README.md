<p align="center">
  <img src="assets/images/onboarding_quran.png" alt="وِصَال — Wesal" width="160" />
</p>

<h1 align="center">وِصَال · Wesal</h1>

<p align="center">
  <b>منصة عربية متكاملة لإدارة حلقات تحفيظ القرآن — متابعة منظّمة بدل المجموعات المبعثرة.</b><br/>
  <i>An all-in-one Arabic platform for managing Qur'an memorization circles — on web &amp; mobile.</i>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black" />
  <img alt="BLoC" src="https://img.shields.io/badge/Architecture-BLoC%20%2B%20Clean-2E7D52" />
  <img alt="Platforms" src="https://img.shields.io/badge/Platforms-Web%20·%20Android%20·%20iOS-444" />
</p>

---

## 🧩 The Problem

Most Qur'an memorization circles today are run over Telegram and WhatsApp groups,
where follow-up gets scattered: messages get lost, there's no structured way to
track memorization, attendance, or assessment, and a teacher can't easily see
each student's level or pair students for recitation.

## 🌿 The Solution

**وِصَال (Wesal)** brings the whole circle into one organized place instead of
scattered chat groups, connecting the teacher to her students with precise,
structured follow-up — across **web and mobile**.

## ✨ Features

- **Circle & member management** with clear roles: _teacher · supervisor · student_.
- **Live sessions** on a weekly schedule, with a unified calendar across all circles.
- **Daily recitation (التسميع)** with a partner — recorded by the student herself.
- **Weekly memorization plan (الحفظ)** set by the teacher per circle and graded after each lesson.
- **Tracking** of attendance, weekly assignments, exams, and results.
- **Real-time notifications** for every teacher action, plus circle announcements.
- **Reports dashboard** showing each student's progress.

## 👥 Roles

| Role | Capabilities |
|------|--------------|
| **Teacher (معلّمة)** | Owns circles, publishes schedules & weekly plans, runs live sessions, grades exams, manages members and reports. |
| **Supervisor (مشرفة)** | Assists the teacher with day-to-day follow-up (scoped permissions). |
| **Student (طالبة)** | Records daily recitation with her partner, follows her plan, sees her progress, joins sessions and exams. |

## 🎯 Target Audience

Qur'an teachers, memorization centers and their students — and any study circle
that needs organized follow-up instead of ad-hoc chat groups.

---

## 🛠️ Tech Stack

- **Flutter** (cross-platform: web, Android, iOS, desktop) with a full **RTL Arabic** UI.
- **State management:** `flutter_bloc` (BLoC pattern) over a clean, layered architecture.
- **Dependency injection:** `get_it` + `injectable` (generated `injection.config.dart`).
- **Backend:** Firebase — Authentication, Cloud Firestore, Storage.
- **Charts & UI:** `fl_chart`, `table_calendar`, Google Fonts (Cairo / Tajawal).

## 🏗️ Architecture

The codebase follows a clean, layered structure:

```
lib/
├── domain/          # Models, repository contracts (pure Dart, no Flutter/Firebase)
├── data/            # Repository implementations, data sources, DTOs (Firestore)
├── presentation/    # Feature UI: pages + BLoCs (auth, circle, task, exam, …)
└── core/            # DI, theme, shared widgets, utilities
```

Each feature is organized by domain (auth, circles, sessions, tasks/homework,
exams, reports, notifications) with its own models, repository, and BLoC.

---

## 🚀 Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Regenerate DI code (injection.config.dart)
dart run build_runner build --delete-conflicting-outputs

# 3. Run
flutter run -d chrome        # web (dev)
flutter run                  # mobile (connected device / emulator)

# 4. Production web build  ->  build/web
flutter build web
```

> **Firebase:** the project ships with a Firebase config. To use your own backend,
> replace `lib/firebase_options.dart` and the platform `google-services.json` /
> `GoogleService-Info.plist`, and deploy `firestore.rules`.

### Web compatibility notes

- `dart:io` does not leak into shared code. The HTTP client is created through a
  conditional-import factory (`lib/core/interceptor/client_factory.dart`):
  `IOClient` natively, `BrowserClient` on web.
- Connectivity is checked via a conditional-import helper
  (`lib/core/network/connectivity_helper.dart`): a socket lookup natively,
  `navigator.onLine` on web.
- The UI is responsive — content is centered and width-capped so it reads well on
  wide desktop/web viewports instead of stretching edge to edge.

---

## 🏆 Hackathon

The first version of **وِصَال** was built during **هاكاثون قبيلة (Qabilah Hackathon)**.
Projects that can grow into a real business or open-source product have the best
chance — and Wesal is built to do exactly that. 🤍

---

<p align="center"><sub>صُنع بحبٍّ لخدمة معلّمات كتاب الله وطالباته · Made with ❤️ for Qur'an circles</sub></p>
