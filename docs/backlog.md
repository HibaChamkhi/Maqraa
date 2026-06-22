# وِصَال — Backlog (teacher/supervisor features)

> Status of the teacher-side work. Tags: **[DONE]** · **[FIX]** = built but needs work · **[NEW]** = not started. Priority: **P1** · **P2** · **P3**.
> Last updated: 2026-06-22 · Branch: `feature/integration`

---

## 0. Blockers / infra

- **[DONE] Publish Firestore rules.** Published to the live project; attendance/exam/session writes work.
- **[FIX][P1] Run `flutter analyze` + smoke test.** Most work was written without a local analyzer run (no SDK in the build sandbox); compile errors are fixed reactively. Do a full analyze pass before release.
- **[NEW][P2] Tighten Firestore rules.** Still permissive (any signed-in user can read/write any circle). Scope to circle membership + role.
- **[NEW][P3] Tests.** No automated tests yet.

---

## 1. Authorities (teacher vs supervisor)

- **[DONE] Circle-scoped permission helper** — unified "role in THIS circle" check (merged from tasks branch).
- **[DONE] Demote supervisor / remove member / transfer ownership** (merged — verify each path).
- **[NEW][P2] Teacher-vs-supervisor power limits.** Confirm supervisor can't delete circle / change privacy / manage supervisors / transfer ownership.
- **[NEW][P2] Enforce authorities in Firestore rules** (server-side).

---

## 2. الاختبارات (Exams)

Done: create (popup, type, range, marks, date+time), edit, delete, grade per student (score, attendance, feedback, auto grade + pass/fail), publish gate, inline tab, student view.

- **[DONE] Stale publish badge** refresh (merged).
- **[NEW][P2] Multi-criteria rubric** — حفظ / تجويد / طلاقة weighted (currently single score).
- **[NEW][P2] Results CSV export.**
- **[NEW][P2] Exam reminder** — wire `scheduleExamReminder` to the exam date/time.
- **[NEW][P3] Retakes.**
- **[NEW][P3] Certificates** for ختمة / إجازة.

---

## 3. الطالبات (Students table)

Done: new columns (تسميع اليوم, تقدّم الحفظ, التقييم, الشريكة, إجراءات), expandable detail.

- **[DONE] Narrow-screen student card** updated with الشريكة / تسميع اليوم (merged).
- **[DONE] Member `contact` + `notes` fields** + attendance % in the detail panel (merged).
- **[NEW][P3] Latest exam result** in the detail panel (link exams → student).

---

## 4. الحضور (Attendance)

Done: اليوم/الأسبوع switch, weekly grid (students × days), tap to mark حاضرة/غائبة/معذورة, weekly النسبة, per-day store, error feedback.

- **[DONE] Week navigation** (◀ ▶, no future weeks).
- **[DONE] Days now derive from the schedule rule** (no more 7-day fallback when a rule is set).
- **[DONE] Attendance % in the student detail** (merged).
- **[NEW][P2] Feed attendance % into التقارير** (trends over time).
- **[NEW][P2] Auto-fill attendance from a live session** (joining marks present).
- **[NEW][P3] Month / term view.**

---

## 5. Sessions (fixed-rule model) — see `sessions_logic_spec.md`

- **[DONE] الجدول الثابت rule editor** (days + time + duration) in the الجلسات tab; live-refreshes أيام الحلقة + attendance columns.
- **[DONE] Generated occurrences** — القادمة + السجل (منتهية via attendance, else فائتة), no doc per occurrence.
- **[DONE] Materialize-on-start** — بدء today's occurrence creates + starts the session and opens live.
- **[DONE] Exceptions** — cancel / move a specific date + add one-off (استثنائية).
- **[DONE] Live screen today-only** (no backlog of old scheduled sessions).
- **[DONE] Calendar tap-to-act popup** — start / join / cancel a session from the weekly calendar.
- **[DONE] Notify circle students** on cancel / move.
- **[NEW][P3] Notify on edit-form modify** (the «جلسة جديدة»/edit form doesn't notify yet — only calendar + الجلسات tab do).
- **[FIX][P3] Dedupe materialize** — tapping بدء twice can create duplicate session docs.

---

## 6. Circles & layout

Done: الحلقات redesign (KPI strip + card grid + add tile), centered content on إنشاء حلقة + معلومات الحلقة, drawer label fix, NestedScrollView workspace (scrolling header + pinned tabs), rename circle (تعديل الحلقة).

- **[NEW][P2] Roll `CenteredContent` across remaining pages** (profile, settings, join circle, reports, all-students).
- **[NEW][P3] "Next session" chip** on circle cards.

---

## Suggested next order

1. `flutter analyze` pass + smoke test the merged build (Section 0).
2. Confirm teacher-vs-supervisor power limits + tighten Firestore rules (1, 0).
3. Feed attendance % into التقارير (4).
4. Exams polish: rubric, CSV export, reminder (2).
5. Finish layout sweep + remaining nice-to-haves (6, 3, 5).
