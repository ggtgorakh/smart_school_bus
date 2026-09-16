# FINAL AUDIT PROMPT — Smart School Bus Tracking and Student Safety System

## Ground Rules (read first — these override everything else if there's ever a conflict)

1. **Do not edit, refactor, or delete any code during the audit phase.** This is a read-and-report task. Only propose fixes; do not apply them unless explicitly asked in a follow-up.
2. **Hard constraints — do not violate these under any circumstance, even as a "recommendation":**
   - No RFID, QR, or camera-based scanning of any kind.
   - No ESP32, external GPS module, or GSM module — the driver's smartphone is the only GPS source.
   - No new "AI features," route optimization, or advanced additions. The goal is a reliable, low-cost, working system — not a bigger one.
3. **Every issue you report must cite the exact file and, where possible, line number or function name.** Vague issues ("tracking might have bugs") are not acceptable — trace the actual code path and quote what you found.
4. **Verify, don't trust prior claims.** If you find a comment, doc, or note claiming something works (e.g. "8/8 tests passed"), re-run it yourself (`flutter analyze`, `flutter test`, relevant greps) and report what you actually observed, not what was claimed.
5. **If something cannot be verified from static code alone** (e.g., real device lock-screen GPS behavior, actual Firebase security rule enforcement under load), put it in **"Unverified / Requires Physical Testing"** — never guess pass/fail.
6. **Do not assume a feature works because the code exists.** Trace the real execution path from trigger to Firebase write to UI update.

---

## Role

Act as a Senior Flutter Architect, Firebase Engineer, Mobile Security Reviewer, QA Lead, and Final-Year Project Technical Evaluator, performing a production-style final review.

---

## 1. Project Context

**Smart School Bus Tracking and Student Safety System** — a low-cost final-year B.Tech project.

Confirmed design decisions (treat as fixed, not open for debate):
1. No hardware installation (no ESP32/external GPS/GSM module).
2. The Driver's smartphone is the GPS source; it sends coordinates during an active trip.
3. Firebase Realtime Database provides real-time location updates.
4. Parents and Admin monitor the bus in real time.
5. RFID/QR/scanner attendance has been completely removed — attendance is manual.
6. The system must not add unnecessary workload to the driver.
7. The project must remain low-cost and practical.

---

## 2. Roles to Audit

ADMIN, DRIVER, CONDUCTOR, PARENT. For each, verify:
- Access is limited to authorized screens only.
- No access to another role's protected data.
- Correct navigation and correct Firebase permissions.
- Correct logout behavior.
- Role restrictions cannot be bypassed via navigation or direct Firebase access.

---

## 3. Admin Module

Audit: dashboard, bus/student/parent/driver/conductor/user management, fleet management, student/bus/driver/conductor assignment, route planning, stops, live tracking, trip monitoring, notifications, attendance visibility.

Verify all CRUD operations:
- Write correct data to Firebase.
- Read the same schema other screens expect.
- Don't create orphaned records or break existing assignments.
- Properly handle deleted/changed users, buses, or students.

---

## 4. Driver Module

Audit: login, assigned bus/route info, trip operations (Start / Active / Pause / Resume / Complete / Cancel), GPS tracking lifecycle, logout cleanup.

**Expected tracking flow:**
```
Driver starts trip
    ↓
Trip becomes active
    ↓
LocationService.startTracking(busId)
    ↓
Phone GPS starts streaming
    ↓
Coordinates written to Firebase
    ↓
Parent/Admin receive real-time updates
```

Verify GPS tracking does **NOT** start:
- Before a valid active trip.
- Without a valid assigned bus.
- More than once for the same trip (double-tap, rebuild, resume, relogin).

Confirm:
- Only one location stream exists at a time.
- Multiple foreground services cannot start accidentally.
- Invalid trip states cannot trigger tracking.

---

## 5. Phone GPS Migration Audit

Audit `geolocator`, `flutter_background_service`, `permission_handler` usage.

**Android:** `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` (where required), `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, correct foreground service declaration, Android 14+ compatibility.

**iOS:** `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `UIBackgroundModes` with `location`.

Review `location_service.dart` for:
- Permission handling (denied, permanently denied, GPS disabled, location services disabled).
- Null/invalid coordinates.
- Start/stop tracking, stream cancellation.
- Background service and foreground notification lifecycle.
- Memory/resource leaks.

**Intended config:** high-accuracy position stream, ~20m distance filter — confirm the actual code matches this.

**Specifically check for duplicate streams/services caused by:**
double-tapping Start Trip, screen rebuilds, app lifecycle events, returning to screen, restoring an active trip, logout/login.

---

## 6. Trip Workflow Audit

States: `scheduled → preparing → active → paused → completed / cancelled`.

Verify only valid transitions are possible (e.g., `completed → active`, `cancelled → active`, `completed → paused` should be blocked unless explicitly supported).

Confirm:
```
Start/Complete/Cancel Trip → GPS stops → notification clears → bus status = idle → speed = 0
```

**Crash/edge scenarios to trace:** app crash mid-trip, phone restart mid-trip, battery dies mid-trip, internet disconnects mid-trip.

**Stale data check:** can an old Firebase location incorrectly appear as live? Review `lastUpdated` usage. If data can go stale, recommend UI like "Location unavailable — last updated X minutes ago" rather than silently showing old data as current.

---

## 7. Firebase Realtime Database Audit

Live location path: `/buses/{busId}` — confirm every component (Admin, Driver, Parent, Live Tracking) uses this exact same path.

Expected fields: `lat`, `lng`, `speedKmph`, `status`, `lastUpdated`, `currentStopIndex`, `totalStops`, `currentStopLabel`, `etaMinutes`, `busNumber`.

Check: data type consistency, null safety, missing fields, schema compatibility, defensive defaults, timestamp consistency, incorrect overwrites.

**Critical:** Can a Driver overwrite the entire bus object? The Driver should only be able to write live-tracking fields (location, speed, status, lastUpdated) — not administrative bus data. Review security rules for field-level protection.

---

## 8. GPS Security Audit

Verify via **Firebase rules, not just UI logic**:
- Driver can write location only for their own assigned bus.
- Parent can read only buses assigned to their own children.
- Conductor can access only their assigned bus/students.
- No role can bypass restrictions via direct Firebase access outside the app UI.

Explicitly test for: a driver changing another `busId`, a parent reading another parent's child, and any case where a client-side check exists but the Firebase rule itself allows the access anyway.

---

## 9–12. Parent Module, Child Info, Assigned Staff, Bus & Route

- **Parent module:** multi-child selector; each child shows only their own bus, route, driver, conductor, attendance, and tracking — verify data isolation between siblings.
- **Child Info (~10–12 fields):** confirm clear separation between read-only school-controlled fields (Student ID, Name, School/Class, Division, Roll Number, Assigned Bus, Route) and parent-editable fields (contact info, emergency contact, pickup/drop preference). Verify parents can't edit school-controlled fields, edits persist after restart, and sensitive data isn't unnecessarily exposed to Driver/Conductor.
- **Assigned Staff:** driver/conductor info shown must match the child's *current* bus assignment — no stale cached assignments.
- **Bus & Route:** correct bus/route/stops/location and correct child-to-bus and parent-to-child relationships. No hardcoded default bus (e.g. `bus_01`) unless the database genuinely has that value.

---

## 13. Manual Attendance Audit

Confirm **complete removal** of: QR scanner, RFID scanner, camera scanner, scanner modal/animation, scan-by-ID controls, scanner-specific navigation, dead scanner imports.

Audit manual attendance: search, filtering, Boarded/Not Boarded/Pending/Flagged states, status correction, Mark All Boarded.

Attendance event fields to check: `studentId`, `busId`, `tripId`, `actorUid`, `status`, `source`, `timestamp`, correction info. Verify correct actor/trip recorded, duplicate events handled safely, corrections are auditable, parent sees correct status, and Driver/Conductor can't corrupt another trip's attendance.

---

## 14. Conductor Module

Assigned students, manual attendance, boarding status, corrections, notifications, live trip status, assigned bus access — confirm permissions are correctly scoped.

---

## 15–16. Live Tracking Screen & Maps/ETA

Audit `live_tracking_screen.dart`: Firebase listener lifecycle (no duplicates, no leaks), correct bus selection, marker updates on real coordinate changes, loading/no-location/offline/stale/invalid-coordinate states, prevention of viewing an unauthorized bus.

**ETA:** clearly state whether ETA is real (route distance + current speed) or a static/placeholder value pulled from an existing Firebase field. Report the truth — do not describe a placeholder as "AI-powered" or "optimized."

**Maps:** API key configuration and exposure risk, map loading, marker positioning, route rendering if implemented.

---

## 17. Notifications

Boarding, drop, emergency/SOS (if implemented), trip-related, delivery, Firebase cleanup, duplication. Confirm logout does not delete global notifications, and notifications are scoped to the authenticated user only.

---

## 18. Authentication & Session

Login, logout, role loading, session persistence, invalid session, role mismatch, deleted user, missing profile.

**Specifically:** on Driver logout during an active trip — does GPS tracking stop, does the foreground service stop, is the location stream cancelled, does no background tracking silently continue?

---

## 19. UI/UX Review

Navigation consistency, empty/loading/error states, responsive layout on small and large phones, text overflow, button double-tap protection, disabled/loading button states, correct navigation after role changes, back-button and logout behavior. Prioritize functionality and clarity over cosmetics.

---

## 20. Database Consistency

Trace relationships between Users, Students, Parents, Drivers, Conductors, Buses, Routes, Trips, Attendance Events, Notifications, Live Locations. Look for orphaned records, invalid IDs, deleted-user references, duplicate assignments, multiple active trips for one bus, conflicting bus assignments, stale references.

---

## 21. Offline & Network Behavior

Check behavior on: internet disconnect/reconnect, GPS unavailable, Firebase failure, driver app offline, parent app reconnect. Perfect offline support isn't required — but flag any data-corruption risk.

---

## 22. Automated Test Audit

Run all existing tests yourself and report actual Passed / Failed / Skipped / Missing coverage. Do **not** treat passing widget/unit tests as proof that real GPS, background tracking, lock-screen tracking, or live Firebase sync actually work — clearly separate **Automated Test Results** from **Physical Device Validation**.

---

## 23. Physical Device Test Checklist

Report each as PASS / FAIL / NOT TESTED:

1. Driver logs in on a physical device.
2. Driver starts a valid trip.
3. `/buses/{busId}` updates coordinates in Firebase.
4. Parent logs in on a second device.
5. Map marker moves on the parent screen.
6. Driver app minimized — persistent foreground notification remains visible.
7. Physically move with the driver phone — Firebase coordinates keep updating.
8. Driver phone locked — verify tracking behavior.
9. App restored from background — no duplicate location streams started.
10. Trip ended — GPS stops, stream stops, foreground service stops, notification disappears, bus status → idle, speed → 0.

---

## 24. Performance & Resource Audit

Firebase listener duplication, location update frequency, battery usage risk, memory leaks, stream/timer/controller disposal, excessive Firebase writes.

---

## 25. Dead Code & Cleanup

Search the full project for: old scanner code, QR/RFID references, hardware-GPS/ESP32/GSM-specific code, unused imports/files, duplicate services, deprecated code. **Report what depends on each before recommending removal — do not delete blindly.**

---

## 26. Final End-to-End Flow Verification

```
ADMIN → creates users → creates buses → creates students
      → assigns students to buses → assigns Driver/Conductor → creates routes

DRIVER → logs in → views assigned bus → starts valid trip
       → phone GPS starts → Firebase receives live location

CONDUCTOR → views assigned students → records manual attendance → updates boarding status

PARENT → logs in → selects child → views Child Info → views Assigned Staff
       → views Bus & Route → tracks assigned bus → receives attendance/boarding notifications

DRIVER → ends trip → GPS stops → bus becomes idle
```

Verify every connection in this chain actually works end to end, not just that each screen individually renders.

---

## 27. Final Output Format

**A. Executive Summary** — overall score X/100, broken down by: Architecture, Firebase, Authentication, Role Security, Parent Module, Driver Module, Conductor Module, Admin Module, Manual Attendance, Live Tracking, Phone GPS Tracking, Notifications, UI/UX, Database Integrity, Testing.

**B. Critical Issues** — things that break the app, break security, cause incorrect live tracking, cause incorrect attendance, or corrupt data. For each: Issue / Location (file + line) / Root Cause / Impact / Recommended Fix / Priority.

**C. High Priority Issues** — should fix before final demonstration.

**D. Medium/Low Priority Issues** — non-critical improvements.

**E. Verified Working Features** — only what you actually confirmed by code inspection or test execution. No assumptions.

**F. Unverified Features** — anything requiring physical device or external-service testing to confirm.

**G. Firebase Security Review** — explicit statement on whether rules sufficiently prevent unauthorized reading, writing, cross-role access, cross-bus access, and cross-child access.

**H. Database Consistency Report** — broken relationships, orphan risks, duplicate-assignment risks, stale-data risks.

**I. Physical Device Test Report** — the Section 23 checklist with PASS / FAIL / NOT TESTED for each item.

**J. Final Fix Plan** — the *smallest possible* fix plan:
- Priority 1: must fix before demo.
- Priority 2: should fix before submission.
- Priority 3: optional improvements.

**Reminder:** the goal is a reliable, low-cost, fully functional, secure, well-integrated, demonstrable system — not a bigger one. Do not recommend RFID, QR scanners, ESP32, GSM modules, or new AI features. Do not blindly refactor working code or remove working functionality. Inspect first, trace actual data flow, identify real issues, present the audit — only then propose targeted fixes.
