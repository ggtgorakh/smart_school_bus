// lib/services/roster_import_service.dart
//
// Bulk student/parent roster import from an Admin-uploaded .xlsx file.
//
// Flow (matches the "Import Roster" work paper):
//   1. Admin picks a .xlsx file -> parseWorkbook() builds a preview
//      (per-row: new / update / error) without writing anything.
//   2. Admin reviews the preview and taps Confirm -> commitImport() does
//      the actual Firebase writes: creates any missing Parent accounts
//      (via the existing secondary-app AuthService.createUserByAdmin
//      trick, so the Admin is never signed out), links siblings to a
//      single shared parent account, writes each student under
//      studentRosters/{busId}/{studentId}, and flips imported buses from
//      idle -> onRoute.
//
// This file intentionally does NOT touch UI — see
// lib/screens/admin/import_roster_screen.dart for the file picker +
// preview table + confirm button that drives this service.

import 'dart:math';
import 'package:excel/excel.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/bus_fleet.dart';
import '../models/student.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

/// The columns this importer understands, in the standardized template
/// order (see work paper §5). Order in the actual file doesn't matter —
/// columns are matched by header name — but all of these must be present.
const List<String> rosterRequiredHeaders = [
  'Student ID',
  'Student Name',
  'Class',
  'Section',
  'Parent Name',
  'Parent Email',
  'Parent Phone',
  'Bus ID',
  'Route ID',
  'Stop ID',
  'Stop Name',
];

enum RosterRowAction { newStudent, updateStudent, error }

class RosterImportRow {
  final int excelRowNumber; // 1-based, matches what the Admin sees in Excel
  final String studentId;
  final String studentName;
  final String studentClass;
  final String section;
  final String parentName;
  final String parentEmail; // normalized: trimmed, lowercased
  final String parentPhone;
  final String busIdRaw;
  final String? busId; // normalized (e.g. bus_01), null if invalid
  final String routeId;
  final String stopId;
  final String stopName;
  final RosterRowAction action;
  final List<String> errors;

  // Populated during parse if this row updates an existing student, so
  // commitImport() can preserve live attendance state instead of
  // resetting a boarded child back to "pending".
  final StudentStatus? existingStatus;
  final DateTime? existingBoardedAt;

  const RosterImportRow({
    required this.excelRowNumber,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
    required this.section,
    required this.parentName,
    required this.parentEmail,
    required this.parentPhone,
    required this.busIdRaw,
    required this.busId,
    required this.routeId,
    required this.stopId,
    required this.stopName,
    required this.action,
    required this.errors,
    this.existingStatus,
    this.existingBoardedAt,
  });

  bool get isValid => action != RosterRowAction.error;

  String get grade {
    final parts = [studentClass, section].where((s) => s.trim().isNotEmpty);
    return parts.isEmpty ? '' : parts.join(' - ');
  }
}

class RosterParentGroup {
  final String email; // normalized key
  final String name;
  final String phone;
  final bool alreadyExists;
  final String? existingUid;
  final List<int> excelRowNumbers;

  const RosterParentGroup({
    required this.email,
    required this.name,
    required this.phone,
    required this.alreadyExists,
    required this.existingUid,
    required this.excelRowNumbers,
  });
}

class RosterImportPreview {
  final List<RosterImportRow> rows;
  final List<RosterParentGroup> parentGroups;

  const RosterImportPreview({required this.rows, required this.parentGroups});

  int get newStudentCount => rows.where((r) => r.action == RosterRowAction.newStudent).length;
  int get updateStudentCount => rows.where((r) => r.action == RosterRowAction.updateStudent).length;
  int get errorCount => rows.where((r) => r.action == RosterRowAction.error).length;
  int get newParentCount => parentGroups.where((g) => !g.alreadyExists).length;
  int get existingParentCount => parentGroups.where((g) => g.alreadyExists).length;
}

class RosterImportSummary {
  final int studentsAdded;
  final int studentsUpdated;
  final int parentAccountsCreated;
  final int busesActivated;
  final List<String> rowErrors; // non-fatal per-row failures during commit

  const RosterImportSummary({
    required this.studentsAdded,
    required this.studentsUpdated,
    required this.parentAccountsCreated,
    required this.busesActivated,
    required this.rowErrors,
  });
}

/// Thrown when the workbook itself can't be understood (wrong template,
/// no sheets, missing required columns) — distinct from per-row errors,
/// which are surfaced in the preview instead of thrown.
class RosterTemplateException implements Exception {
  final String message;
  RosterTemplateException(this.message);
  @override
  String toString() => message;
}

class RosterImportService {
  RosterImportService._();
  static final RosterImportService instance = RosterImportService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final Random _random = Random.secure();

  // ============================================================
  // PARSE / PREVIEW (read-only — safe to call as many times as needed)
  // ============================================================

  Future<RosterImportPreview> parseWorkbook(List<int> bytes) async {
    // Reset scratch state from any previous parse before starting a new one.
    _existingStudentCache.clear();

    final Excel workbook;
    try {
      workbook = Excel.decodeBytes(bytes);
    } catch (error) {
      throw RosterTemplateException(
        'Could not read this file as an Excel workbook. Please export it as .xlsx and try again.',
      );
    }

    if (workbook.tables.isEmpty) {
      throw RosterTemplateException('The workbook has no sheets.');
    }

    // Prefer a sheet literally named "Students"; otherwise use the first one.
    final sheetName = workbook.tables.keys.firstWhere(
      (name) => name.trim().toLowerCase() == 'students',
      orElse: () => workbook.tables.keys.first,
    );
    final sheet = workbook.tables[sheetName]!;
    final allRows = sheet.rows;
    if (allRows.isEmpty) {
      throw RosterTemplateException('The "$sheetName" sheet is empty.');
    }

    // --- Header row ---
    final headerRow = allRows.first;
    final Map<String, int> columnIndex = {};
    for (int i = 0; i < headerRow.length; i++) {
      final header = _cellText(headerRow[i]?.value).trim();
      if (header.isNotEmpty) {
        columnIndex[header.toLowerCase()] = i;
      }
    }

    final missingHeaders = rosterRequiredHeaders
        .where((h) => !columnIndex.containsKey(h.toLowerCase()))
        .toList();
    if (missingHeaders.isNotEmpty) {
      throw RosterTemplateException(
        'Missing required column(s): ${missingHeaders.join(', ')}. '
        'Expected headers: ${rosterRequiredHeaders.join(' | ')}.',
      );
    }

    String cellAt(List<Data?> row, String header) {
      final idx = columnIndex[header.toLowerCase()];
      if (idx == null || idx >= row.length) return '';
      return _cellText(row[idx]?.value);
    }

    // --- Data rows ---
    final List<RosterImportRow> rows = [];
    final Set<String> seenBusStudentKeys = {}; // dedupe within this sheet
    final Map<String, List<String>> rosterCache = {}; // busId -> existing student ids

    for (int r = 1; r < allRows.length; r++) {
      final row = allRows[r];
      final excelRowNumber = r + 1; // 1-based, matches what Excel shows

      final studentId = cellAt(row, 'Student ID').trim();
      final studentName = cellAt(row, 'Student Name').trim();

      // Skip fully-blank trailing rows silently instead of flagging them.
      if (studentId.isEmpty && studentName.isEmpty) continue;

      final studentClass = cellAt(row, 'Class').trim();
      final section = cellAt(row, 'Section').trim();
      final parentName = cellAt(row, 'Parent Name').trim();
      final parentEmailRaw = cellAt(row, 'Parent Email').trim();
      final parentEmail = parentEmailRaw.toLowerCase();
      final parentPhone = cellAt(row, 'Parent Phone').trim();
      final busIdRaw = cellAt(row, 'Bus ID').trim();
      final routeId = cellAt(row, 'Route ID').trim();
      final stopId = cellAt(row, 'Stop ID').trim();
      final stopName = cellAt(row, 'Stop Name').trim();

      final errors = <String>[];
      if (studentId.isEmpty) errors.add('Student ID is required');
      if (studentName.isEmpty) errors.add('Student Name is required');
      if (parentName.isEmpty) errors.add('Parent Name is required');
      if (parentEmail.isEmpty) {
        errors.add('Parent Email is required (needed to create the parent login)');
      } else if (!_emailPattern.hasMatch(parentEmail)) {
        errors.add('Parent Email "$parentEmailRaw" is not a valid email address');
      }

      final busId = normalizeBusId(busIdRaw);
      if (busId == null) {
        errors.add('Bus ID "$busIdRaw" is invalid (expected e.g. BUS-01 through BUS-${FirebaseService.totalFleetSize})');
      }

      // Duplicate Student ID for the same bus within this sheet.
      if (busId != null && studentId.isNotEmpty) {
        final key = '$busId/$studentId';
        if (!seenBusStudentKeys.add(key)) {
          errors.add('Duplicate Student ID "$studentId" for $busId elsewhere in this sheet');
        }
      }

      RosterRowAction action = errors.isNotEmpty ? RosterRowAction.error : RosterRowAction.newStudent;
      StudentStatus? existingStatus;
      DateTime? existingBoardedAt;

      if (busId != null && studentId.isNotEmpty && errors.isEmpty) {
        // Look up existing roster for this bus (cached across rows).
        final existingIds = rosterCache.putIfAbsent(busId, () => []);
        if (!rosterCache.containsKey('$busId::loaded')) {
          try {
            final snapshot = await _root.child('studentRosters/$busId').get();
            final value = snapshot.value;
            if (value is Map) {
              existingIds.addAll(value.keys.map((k) => k.toString()));
              // Stash existing status/boardedAt per student for later reuse.
              value.forEach((key, val) {
                if (val is Map) {
                  final existing = Student.fromMap(val, id: key.toString());
                  _existingStudentCache['$busId/$key'] = existing;
                }
              });
            }
            rosterCache['$busId::loaded'] = [];
          } catch (_) {
            // If the read fails, fall back to treating every row as "new" —
            // commitImport() uses set() either way, so this is safe, just
            // less informative in the preview.
          }
        }

        if (existingIds.contains(studentId)) {
          action = RosterRowAction.updateStudent;
          final existing = _existingStudentCache['$busId/$studentId'];
          existingStatus = existing?.status;
          existingBoardedAt = existing?.boardedAt;
        }
      }

      rows.add(RosterImportRow(
        excelRowNumber: excelRowNumber,
        studentId: studentId,
        studentName: studentName,
        studentClass: studentClass,
        section: section,
        parentName: parentName,
        parentEmail: parentEmail,
        parentPhone: parentPhone,
        busIdRaw: busIdRaw,
        busId: busId,
        routeId: routeId,
        stopId: stopId,
        stopName: stopName,
        action: action,
        errors: errors,
        existingStatus: existingStatus,
        existingBoardedAt: existingBoardedAt,
      ));
    }

    final parentGroups = await _buildParentGroups(rows);
    return RosterImportPreview(rows: rows, parentGroups: parentGroups);
  }

  // Scratch cache used only during a single parseWorkbook() call.
  final Map<String, Student> _existingStudentCache = {};

  Future<List<RosterParentGroup>> _buildParentGroups(List<RosterImportRow> rows) async {
    final Map<String, List<RosterImportRow>> grouped = {};
    for (final row in rows) {
      if (row.action == RosterRowAction.error) continue;
      grouped.putIfAbsent(row.parentEmail, () => []).add(row);
    }

    final List<RosterParentGroup> groups = [];
    for (final entry in grouped.entries) {
      final email = entry.key;
      final rowsForParent = entry.value;
      final firstNamed = rowsForParent.firstWhere(
        (r) => r.parentName.isNotEmpty,
        orElse: () => rowsForParent.first,
      );
      final firstPhoned = rowsForParent.firstWhere(
        (r) => r.parentPhone.isNotEmpty,
        orElse: () => rowsForParent.first,
      );

      String? existingUid;
      try {
        final snapshot = await _root
            .child('users')
            .orderByChild('email')
            .equalTo(email)
            .get();
        // Note: Firebase Realtime DB matching here is on the exact stored
        // casing of "email". We query with the lowercased value since that
        // is how this importer always writes new parent emails; a
        // pre-existing account saved with different casing will not be
        // detected and a duplicate account may be created instead.
        if (snapshot.exists && snapshot.value is Map) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          existingUid = data.keys.first.toString();
        }
      } catch (_) {
        // Leave existingUid null — commitImport() will just attempt to
        // create a new account, and Firebase Auth's own
        // email-already-in-use error is handled there as a fallback.
      }

      groups.add(RosterParentGroup(
        email: email,
        name: firstNamed.parentName,
        phone: firstPhoned.parentPhone,
        alreadyExists: existingUid != null,
        existingUid: existingUid,
        excelRowNumbers: rowsForParent.map((r) => r.excelRowNumber).toList(),
      ));
    }
    return groups;
  }

  // ============================================================
  // COMMIT (writes to Firebase)
  // ============================================================

  Future<RosterImportSummary> commitImport(RosterImportPreview preview) async {
    await FirebaseService.instance.ensureTenBusesExist();

    final validRows = preview.rows.where((r) => r.isValid).toList();
    final List<String> rowErrors = [];
    int parentAccountsCreated = 0;

    // 1. Resolve every parent group to a UID, creating accounts as needed.
    final Map<String, String> emailToUid = {};
    for (final group in preview.parentGroups) {
      if (group.alreadyExists && group.existingUid != null) {
        emailToUid[group.email] = group.existingUid!;
        continue;
      }
      try {
        final tempPassword = _generateTempPassword();
        final credential = await AuthService.instance.createUserByAdmin(
          email: group.email,
          password: tempPassword,
          name: group.name.isEmpty ? 'Parent' : group.name,
          role: 'Parent',
          phone: group.phone.isEmpty ? null : group.phone,
        );
        final uid = credential.user?.uid;
        if (uid != null) {
          emailToUid[group.email] = uid;
          parentAccountsCreated++;
          // Passive credential handoff: the parent sets their own password
          // via the reset link. Nobody — including the Admin — ever
          // needs to know or share a real password.
          await AuthService.instance.sendPasswordResetEmail(group.email);
        }
      } catch (error) {
        rowErrors.add('Parent account for ${group.email} could not be created: $error');
      }
    }

    // 2. Write each valid student row.
    int added = 0;
    int updated = 0;
    final Set<String> busesTouched = {};

    for (final row in validRows) {
      final busId = row.busId!;
      final parentUid = emailToUid[row.parentEmail];
      if (parentUid == null) {
        rowErrors.add('Row ${row.excelRowNumber} (${row.studentName}): no parent account available, skipped');
        continue;
      }

      final student = Student(
        id: row.studentId,
        name: row.studentName,
        grade: row.grade.isEmpty ? '' : row.grade,
        seat: '',
        photoUrl: '',
        status: row.existingStatus ?? StudentStatus.pending,
        stopName: row.stopName,
        boardedAt: row.existingBoardedAt,
        parentUid: parentUid,
        parentName: row.parentName,
        parentPhone: row.parentPhone,
        busId: busId,
      );

      try {
        await FirebaseService.instance.upsertStudent(busId: busId, student: student);
        busesTouched.add(busId);
        if (row.action == RosterRowAction.updateStudent) {
          updated++;
        } else {
          added++;
        }
      } catch (error) {
        rowErrors.add('Row ${row.excelRowNumber} (${row.studentName}): failed to save — $error');
      }
    }

    // 3. Flip touched buses from idle -> onRoute. A bus that's already
    // delayed/maintenance/onRoute (real hardware/admin state) is left
    // exactly as-is — importing a roster never overwrites live bus status.
    int busesActivated = 0;
    if (busesTouched.isNotEmpty) {
      try {
        final currentFleet = await FirebaseService.instance.streamFleet().first;
        final idleBusIds = currentFleet
            .where((b) => b.status == FleetStatus.idle && busesTouched.contains(b.busId))
            .map((b) => b.busId)
            .toSet();
        for (final busId in idleBusIds) {
          await FirebaseService.instance.updateFleetStatus(busId, FleetStatus.onRoute);
          busesActivated++;
        }
      } catch (error) {
        rowErrors.add('Could not update fleet status for imported buses: $error');
      }
    }

    return RosterImportSummary(
      studentsAdded: added,
      studentsUpdated: updated,
      parentAccountsCreated: parentAccountsCreated,
      busesActivated: busesActivated,
      rowErrors: rowErrors,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Normalizes "BUS-01", "Bus_2", "bus03", etc. into the app's canonical
  /// bus_XX form, bounded to the real fleet size. Returns null if no valid
  /// bus number (1..totalFleetSize) can be found.
  String? normalizeBusId(String raw) {
    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match == null) return null;
    final n = int.tryParse(match.group(1)!);
    if (n == null || n < 1 || n > FirebaseService.totalFleetSize) return null;
    return 'bus_${n.toString().padLeft(2, '0')}';
  }

  String _generateTempPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%';
    return List.generate(14, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Extracts a plain string from an `excel` package cell value. Written
  /// defensively against `.value` (used by TextCellValue/IntCellValue/
  /// DoubleCellValue/BoolCellValue in excel v4+) since it's the one
  /// surface most likely to shift between package versions.
  String _cellText(CellValue? cellValue) {
    if (cellValue == null) return '';
    try {
      final dynamic inner = (cellValue as dynamic).value;
      if (inner != null) {
        if (inner is double && inner == inner.roundToDouble()) {
          return inner.toInt().toString();
        }
        return inner.toString().trim();
      }
    } catch (_) {
      // Fall through for cell types without a simple `.value` (formulas,
      // rich text, etc.) — this template shouldn't contain any, but a raw
      // toString() keeps the row visible (likely as a validation error)
      // instead of crashing the whole import.
    }
    return cellValue.toString().trim();
  }
}