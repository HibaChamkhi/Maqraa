# وِصَال — Sessions logic (spec)

> Design spec for how a حلقة's sessions work. Approved model: **fixed recurring
> rule + per-date exceptions + generated occurrences**. No implementation yet.
> Last updated: 2026-06-22

---

## 1. The core idea

A حلقة has a **fixed weekly rule** set by the teacher (e.g. الإثنين والخميس · ٦:٠٠ ص · ٦٠ دقيقة).
Sessions are **generated** from that rule — they are *not* stored one-by-one.
A session is persisted to the database **only** when it deviates from the rule or
actually happens. This avoids a pile of stale docs and keeps one source of truth.

Mental model: a repeating calendar event — set "every Monday", it shows all
Mondays, you only touch a single date to move/cancel it.

---

## 2. What is stored vs generated

**Stored on the حلقة (the rule):** `days` + `dayTimes` + `durationMinutes`
(already exist on the Circle model). This is the single source of truth for the
schedule, **أيام الحلقة**, and the attendance-grid columns.

**Stored as a per-date record — only when needed:**
- **استثنائية (extra):** a one-off session outside the rule.
- **معدّلة / مؤجّلة (moved):** a specific occurrence whose time changed.
- **ملغاة (cancelled):** a specific occurrence removed.
- **حدثت (happened):** once started — holds the join link + attendance + outcome.

**Generated (not stored):** every normal weekly occurrence. Computed on the fly
for the visible date range = rule occurrences − cancelled + moved + extras.

---

## 3. Statuses (derived, never guessed)

| Status | Meaning | Where it shows |
|---|---|---|
| قادمة (upcoming) | future occurrence | الجلسات tab (القادمة) |
| مباشرة (live) | started and running now | الجلسة المباشرة (active) |
| منتهية (ended) | was started, then ended | السجل |
| **فائتة (missed)** | its day/time passed, never started | السجل (auto) |

**Rule (approved):** a never-started occurrence becomes **فائتة automatically**
once its scheduled time passes, so it leaves the live screen.

---

## 4. Starting a session (approved)

- The teacher can press **بدء** **anytime on or after** the session's scheduled
  time (start early/late allowed).
- **Today's** session is **highlighted** on the live screen.
- Starting creates/updates the "happened" record (status → مباشرة), captures the
  join link, and opens attendance. Ending sets status → منتهية.

---

## 5. Screen behaviour

**الجلسات tab (manage):**
1. The fixed rule at top — editable (days, time, duration). This is also where
   «أيام الحلقة» comes from.
2. القادمة — generated upcoming occurrences (+ extras), each editable: تعديل وقت /
   إلغاء / إضافة جلسة استثنائية.
3. السجل — past occurrences: منتهية and فائتة.

**الجلسة المباشرة (run):**
- Shows **today's** due session(s) only, with بدء. Never a backlog of old ones.
- If one is already live, show it as active with the join link + attendance.

**أيام الحلقة card + attendance grid:**
- Both read the **rule** directly → always consistent (fixes the current mismatch
  where the card read sessions and the grid read a different field).

---

## 6. Why this is efficient

- One rule per حلقة instead of a document per occurrence forever.
- The DB only grows with things that actually happened or were explicitly changed.
- No more "two screens, two filters" inconsistency — date vs status is replaced by
  one derived-status model.

---

## 7. Migration from today's setup

Currently every session is an individual `Session` doc (calendar), and «أيام
الحلقة» is reverse-derived from those docs.

Steps to move over:
1. Ensure the حلقة's rule (`days`/`dayTimes`/`durationMinutes`) is populated — add
   a rule editor in the الجلسات tab if empty.
2. Generate occurrences from the rule for display (range = visible weeks).
3. Treat existing session docs as either **happened** records (keep, as history)
   or **extras/exceptions** (keep, attached to their date).
4. Switch «أيام الحلقة» + attendance grid to read the rule.
5. Apply auto-**فائتة** to past never-started occurrences.

---

## 8. Build order — status

1. **[DONE]** Rule editor in the الجلسات tab (days/time/duration).
2. **[DONE]** Occurrence generator (rule → dated occurrences) + status derivation.
3. **[DONE]** الجلسات tab = rule + القادمة + السجل from the generator.
4. **[DONE]** الجلسة المباشرة = today-only; start anytime on/after time.
5. **[DONE]** Exceptions: move / cancel / add-extra per date.
6. **[DONE]** أيام الحلقة + attendance grid read the rule (fallback to sessions when no rule).

Extras shipped beyond the original plan:
- **[DONE]** Materialize-on-start (بدء a generated occurrence creates + starts the session).
- **[DONE]** Calendar tap-to-act popup (start / join / cancel from the weekly calendar).
- **[DONE]** Notify circle students on cancel / move.

Still open:
- **[NEW]** Notify students when a session is edited via the «جلسة جديدة»/edit form.
- **[FIX]** Dedupe materialize-on-start (double-tap can create duplicate docs).
- **[NEW]** Optional dedicated "started/ended" record for precise منتهية (currently inferred from attendance).
