// lib/screens/admin/import_roster_screen.dart
//
// Admin-only bulk roster import screen. Reachable from Fleet Management
// and Manage Students app bars — inherits the existing Admin-only gate,
// no new role-check code needed.
//
// File pick -> parse & preview (nothing written yet) -> Admin reviews ->
// Confirm Import -> writes to Firebase via RosterImportService.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/roster_import_service.dart';

enum _ScreenState { picking, parsing, preview, importing, done }

class ImportRosterScreen extends StatefulWidget {
  const ImportRosterScreen({super.key});

  @override
  State<ImportRosterScreen> createState() => _ImportRosterScreenState();
}

class _ImportRosterScreenState extends State<ImportRosterScreen> {
  _ScreenState _state = _ScreenState.picking;
  String? _fileName;
  String? _errorMessage;
  RosterImportPreview? _preview;
  RosterImportSummary? _summary;

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
    });

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() {
      _fileName = file.name;
      _state = _ScreenState.parsing;
    });

    try {
      final preview = await RosterImportService.instance.parseWorkbook(bytes);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _state = _ScreenState.preview;
      });
    } on RosterTemplateException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = _ScreenState.picking;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error while reading the file: $e';
        _state = _ScreenState.picking;
      });
    }
  }

  Future<void> _confirmImport() async {
    final preview = _preview;
    if (preview == null) return;

    setState(() => _state = _ScreenState.importing);
    try {
      final summary = await RosterImportService.instance.commitImport(preview);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _state = _ScreenState.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Import failed partway through: $e';
        _state = _ScreenState.preview;
      });
    }
  }

  void _startOver() {
    setState(() {
      _state = _ScreenState.picking;
      _fileName = null;
      _errorMessage = null;
      _preview = null;
      _summary = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text(
          'Import Roster',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_state) {
            _ScreenState.picking => _buildPicker(context),
            _ScreenState.parsing => _buildLoading('Reading and validating "$_fileName"…'),
            _ScreenState.preview => _buildPreview(context),
            _ScreenState.importing => _buildLoading('Importing students and creating parent accounts…'),
            _ScreenState.done => _buildSummary(context),
          },
        ),
      ),
    );
  }

  // ============================================================
  // STATE 1 — PICK FILE
  // ============================================================

  Widget _buildPicker(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Import a Student Roster',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pick an .xlsx file with columns: Student ID, Student Name, Class, Section, '
              'Parent Name, Parent Email, Parent Phone, Bus ID, Route ID, Stop ID, Stop Name.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ElevatedButton.icon(
            onPressed: _pickFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safetyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.folder_open_rounded, size: 20),
            label: const Text('Choose .xlsx File', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.safetyBlue),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ============================================================
  // STATE 2 — PREVIEW
  // ============================================================

  Widget _buildPreview(BuildContext context) {
    final preview = _preview!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _fileName ?? 'Roster preview',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statChip('${preview.newStudentCount} new', AppColors.successGreen),
            _statChip('${preview.updateStudentCount} updates', AppColors.safetyBlue),
            if (preview.errorCount > 0) _statChip('${preview.errorCount} errors', AppColors.errorRed),
            _statChip('${preview.newParentCount} new parent accounts', AppColors.alertOrange),
            if (preview.existingParentCount > 0)
              _statChip('${preview.existingParentCount} existing parents', AppColors.outline),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: preview.rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildRowCard(context, preview.rows[index]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _startOver,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Choose Different File'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (preview.newStudentCount + preview.updateStudentCount) == 0
                    ? null
                    : _confirmImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safetyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  'Confirm Import (${preview.newStudentCount + preview.updateStudentCount})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRowCard(BuildContext context, RosterImportRow row) {
    final Color badgeColor;
    final String badgeLabel;
    switch (row.action) {
      case RosterRowAction.newStudent:
        badgeColor = AppColors.successGreen;
        badgeLabel = 'NEW';
        break;
      case RosterRowAction.updateStudent:
        badgeColor = AppColors.safetyBlue;
        badgeLabel = 'UPDATE';
        break;
      case RosterRowAction.error:
        badgeColor = AppColors.errorRed;
        badgeLabel = 'ERROR';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.studentName.isEmpty ? '(row ${row.excelRowNumber})' : row.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Row ${row.excelRowNumber}',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${row.busId ?? row.busIdRaw} • ${row.grade.isEmpty ? 'No class' : row.grade} • '
            '${row.parentName.isEmpty ? 'No parent name' : row.parentName}',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (row.errors.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...row.errors.map((e) => Text(
                  '• $e',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.errorRed),
                )),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATE 3 — DONE
  // ============================================================

  Widget _buildSummary(BuildContext context) {
    final summary = _summary!;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppColors.successGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Import Complete',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _statChip('${summary.studentsAdded} students added', AppColors.successGreen),
                _statChip('${summary.studentsUpdated} updated', AppColors.safetyBlue),
                _statChip('${summary.parentAccountsCreated} parent accounts created', AppColors.alertOrange),
                if (summary.busesActivated > 0)
                  _statChip('${summary.busesActivated} buses activated', AppColors.safetyBlue),
              ],
            ),
            if (summary.rowErrors.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Some rows had issues:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.errorRed),
                    ),
                    const SizedBox(height: 6),
                    ...summary.rowErrors.map((e) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('• $e', style: const TextStyle(fontSize: 11.5, color: AppColors.errorRed)),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}