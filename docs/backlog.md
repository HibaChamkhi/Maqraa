# وِصَال — Backlog (teacher/supervisor features)

> Status of the teacher-side work + what's left. Tags: **[FIX]** = built but needs work · **[NEW]** = not started. Priority: **P1** (do first) · **P2** · **P3** (nice-to-have).
> Last updated: 2026-06-18 · Branch: `feature/integration`

---

## 0. Blockers / infra

- **[FIX][P1] Publish Firestore rules.** The `firestore.rules` file allows signed-in access but must be published to the live project (Console → Firestore → Rules → Publish). Without it, attendance/exam writes are denied. *(User reports done — verify writes succeed.)*
- **[FIX][P1] Run `flutter analyze` + fix any issues.** The recent work (exams, students table, attendance) was written without a local analyzer run. Do a full analyze + smoke test before merging onward.
- **[NEW][P2] Tighten Firestore rules.** Currently any signed-in user can read/write any circle. Scope to circle membership + role (see Authorities below).
- **[NEW][P3] Tests.** No automated tests for the new exam/attendance features.

---

## 1. Authorities (teacher vs supervisor) — highest-value area

- **[FIX][P1] Unify permission checks (circle-scoped).** Today checks are inconsistent: `circle_workspace_page` and `circle_members_page` use the *global* account role, while `circle_info_page` uses the circle's `teacherId`/`supervisorIds`. Result: a teacher of one circle can manage screens of a circle she doesn't own. Create ONE helper — "what is this user's role in THIS circle?" — and use it everywhere.
- **[NEW][P2] Demote a supervisor** back to student.
- **[NEW][P2] Remove a member** from a circle (owner/supervisor per matrix).
- **[NEW][P2] Transfer circle ownership** (teacher hands the circle to another).
- **[NEW][P2] Teacher-vs-supervisor power limits.** Supervisor can grade/track/manage students, but NOT delete the circle, change privacy, manage supervisors, or transfer ownership.
- **[NEW][P2] Enforce the above in Firestore rules** (server-side, not just hidden UI).

---

## 2. الاختبارات (Exams)

Done: create (popup, type, range, marks, date+time), edit, delete, grade per student (score, attendance, feedback, auto grade + pass/fail), publish gate, inline tab, student view.

- **[FIX][P2] Stale publish badge.** After toggling نشر النتائج on the results screen, the exams list badge (منشورة/مخفية) only refreshes on reload — refresh it on return.
- **[NEW][P2] Multi-criteria rubric** — separate marks for الحفظ / التجويد / الطلاقة weighted into the total (currently a single score).
- **[NEW][P2] Results CSV export** (reuse the students CSV approach).
- **[NEW][P2] Exam reminder.** Wire the existing `scheduleExamReminder` to the exam's date/time.
- **[NEW][P3] Retakes** — second attempt that keeps history.
- **[NEW][P3] Certificates** for ختمة / إجازة exams.

---

## 3. الطالبات (Students table)

Done: new columns (تسميع اليوم, تقدّم الحفظ, التقييم, الشريكة, إجراءات), expandable detail with available fields.

- **[FIX][P2] Narrow-screen student card** still uses the old layout — update it to match (الشريكة, تسميع اليوم) for phones.
- **[NEW][P2] Detail extras need data:** streak, attendance %, latest exam result, contact, teacher notes. Requires:
  - **[NEW][P2] Add `contact` / parent info** field to the member model.
  - **[NEW][P3] Add `notes`** field to the member model.
  - latest exam + attendance % come from items below.

---

## 4. الحضور (Attendance)

Done: اليوم/الأسبوع switch, weekly grid (students × days), tap to mark حاضرة/غائبة/معذورة, weekly النسبة, per-day store, error feedback.

- **[FIX][P3] 7-day fallback.** When a circle has no meeting days set, the grid shows all 7 columns. Encourage setting meeting days, or trim to days that have records.
- **[NEW][P1] Previous / next week navigation** (◀ ▶) — currently only the current week.
- **[NEW][P2] Feed attendance % into** the student detail panel and into التقارير.
- **[NEW][P2] Auto-fill attendance from live sessions** (a join marks present).
- **[NEW][P3] Month / term view.**

---

## 5. Circles & layout

Done: الحلقات redesign (KPI strip + card grid + add tile), centered content on إنشاء حلقة + معلومات الحلقة, drawer label fix.

- **[NEW][P2] Roll out the `CenteredContent` wrapper** to the remaining content/form pages (profile, settings, join circle, weekly schedule, exams, reports, all-students) for consistent centered layout on wide screens.
- **[NEW][P3] Add a "next session" chip** to circle cards (needs schedule read).

---

## Suggested order for your friend

1. Publish + verify Firestore rules, run `flutter analyze` (Section 0).
2. Unify permission checks (1 — the real bug).
3. Attendance week navigation (4) + feed % to detail/reports.
4. Authorities actions: demote / remove / transfer + power limits (1).
5. Exams polish: rubric, CSV, reminder (2).
6. Layout sweep + narrow student card (5, 3).
