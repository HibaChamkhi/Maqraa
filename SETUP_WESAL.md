# وصال (Wesal) — Setup & Architecture Notes

A Flutter (web + mobile) organizer for Quran-memorization circles. Backend: Firebase
(Auth + Cloud Firestore). Architecture: Clean Architecture + Bloc + injectable/get_it.

## Run these before building (required)

```bash
flutter pub get

# 1) Connect your Firebase project (replaces lib/firebase_options.dart with real keys
#    and drops google-services.json / GoogleService-Info.plist):
dart pub global activate flutterfire_cli
flutterfire configure

# 2) Regenerate dependency injection (injectable). NOTE: injection.config.dart was
#    hand-written to match the code; re-running build_runner keeps it authoritative:
dart run build_runner build --delete-conflicting-outputs

flutter run
```

In the Firebase console enable **Authentication → Email/Password + Phone** and create a
**Cloud Firestore** database.

## Features built (full backlog)

| Epic | Stories |
|---|---|
| Auth + roles + gender | US-01, US-02, US-43, US-36, US-37 |
| Circle management | US-03, US-04, US-05, US-29 (QR), US-38 (privacy), US-39, US-40, US-41 |
| Weekly schedule | US-06, US-07 |
| Daily task | US-08, US-09, US-10 (partner confirm), US-35 (per-student to-do) |
| Progress | US-11, US-12 |
| Sessions + calendar | US-30, US-31, US-32, US-33, US-42 (attendance) |
| Exams | US-20, US-21 |
| Partners | US-16, US-17, US-34 |
| Calls | US-18, US-19 |
| Announcements | US-14 |
| Achievements | US-24 (streaks + badges) |
| Reminders | US-13, US-15 (local notifications) |
| Design | US-22 (RTL + theme), US-23 (dark mode) |

Each epic is a feature module under `lib/{domain,data,presentation}/<feature>/`, mirroring
the `name_feature` example. The only deviation from that example: data sources talk to
Firebase (Auth + Firestore) instead of the REST `HttpInterceptor`.

## Firestore schema

```
users/{uid}                : { name, email, phone, photoUrl, role, gender,
                               progressPages, totalPages, streakCount, lastCompletedDate, badges[] }
circles/{circleId}         : { name, teacherId, gender, privacy('public'|'private'),
                               inviteCode, supervisorIds[], createdAt }
  members/{uid}            : { uid, name, role, status('active'|'pending'), joinedAt }
  schedules/{weekId}       : { weekStart, days{sat..fri}, publishedAt }
  tasks/{yyyy-MM-dd}/students/{uid} : { uid, name, range, status, partnerConfirmed, partnerId, note }
  assignments/{id}         : { studentId, studentName, title, date, done }
  sessions/{id}            : { title, scheduledAt, status('scheduled'|'live'|'ended'), link, createdBy }
    attendance/{uid}       : { uid, name, present, at }
  exams/{id}               : { title, range, date }
    results/{uid}          : { uid, name, score }
  pairs/{id}               : { aId, aName, bId, bName, createdAt }
  appointments/{id}        : { fromId, fromName, toId, toName, time, confirmed }
  calls/{id}               : { title, time, link }
    attendance/{uid}       : { uid, name, present }
  announcements/{id}       : { text, authorId, authorName, createdAt }
```

**Gender separation (US-43):** every user has a `gender`; circle discovery and circle
gender are filtered by it so men's and women's spaces never mix.

## Native setup still needed (not code — platform config)

- **Phone OTP:** add SHA-1/SHA-256 fingerprints to the Firebase Android app; enable Phone
  auth; for iOS add the APNs key / URL scheme.
- **Local notifications (reminders):** Android needs `POST_NOTIFICATIONS` permission + a
  notification icon in the manifest; iOS needs the notifications capability. The service
  uses `AndroidScheduleMode.inexactAllowWhileIdle` to avoid the exact-alarm permission.

## Not implemented (lower-priority backlog, flagged for later)

US-25 (audio recitation upload), US-26 (in-app mushaf ayah display), US-27 (export report),
US-28 (hackathon demo deck). These need extra packages/integrations and were left out of
this build.
```
