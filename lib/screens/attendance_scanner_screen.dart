import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/student.dart';
import '../widgets/scanner_reticle.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  String _scanMode = 'QR'; // QR or RFID
  final List<Student> _students = [
    Student(
      id: 'S1',
      name: 'Liam Johnson',
      grade: 'Grade 3',
      seat: 'Seat 4A',
      photoUrl: 'https://i.pravatar.cc/150?img=12',
      status: StudentStatus.boarded,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S2',
      name: 'Maya Patel',
      grade: 'Grade 4',
      seat: 'Seat 2B',
      photoUrl: 'https://i.pravatar.cc/150?img=47',
      status: StudentStatus.boarded,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S3',
      name: 'Ethan Williams',
      grade: 'Grade 5',
      seat: 'Seat 8C',
      photoUrl: 'https://i.pravatar.cc/150?img=33',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S4',
      name: 'Sophia Garcia',
      grade: 'Grade 2',
      seat: 'Seat 1A',
      photoUrl: 'https://i.pravatar.cc/150?img=26',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S5',
      name: 'Jackson Davis',
      grade: 'Grade 3',
      seat: 'Seat 5D',
      photoUrl: 'https://i.pravatar.cc/150?img=60',
      status: StudentStatus.alert,
      stopName: 'Oak St & Maple Ave',
    ),
  ];

  void _overrideStudent(Student student) {
    setState(() {
      student.status = StudentStatus.boarded;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Override applied: ${student.name} marked as Boarded'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _confirmAllBoarded() {
    setState(() {
      for (var s in _students) {
        s.status = StudentStatus.boarded;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All students confirmed boarded! Route resumed.'),
        backgroundColor: AppColors.safetyBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardedCount =
        _students.where((s) => s.status == StudentStatus.boarded).length;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth >= 768;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildScannerArea()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildManifestArea(boardedCount)),
                    ],
                  )
                : Column(
                    children: [
                      _buildScannerArea(),
                      const SizedBox(height: 16),
                      _buildManifestArea(boardedCount),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildScannerArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Scanner',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.safetyBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      size: 14,
                      color: AppColors.successGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Camera feed simulation viewport
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2638),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const ScannerReticle(isScanning: true),
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Ready to scan Student ID or Boarding Pass',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textMain,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mode toggle buttons (QR vs RFID)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _scanMode = 'QR';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _scanMode == 'QR'
                      ? AppColors.safetyBlue
                      : AppColors.surfaceContainerLow,
                  foregroundColor:
                      _scanMode == 'QR' ? Colors.white : AppColors.textMain,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('QR Mode'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _scanMode = 'RFID';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _scanMode == 'RFID'
                      ? AppColors.safetyBlue
                      : AppColors.surfaceContainerLow,
                  foregroundColor:
                      _scanMode == 'RFID' ? Colors.white : AppColors.textMain,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.contactless, size: 20),
                label: const Text('RFID Mode'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManifestArea(int boardedCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manifest header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stop 3: Oak St & Maple Ave',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.safetyBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                  ),
                  Text(
                    '$boardedCount of ${_students.length} boarded',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$boardedCount/${_students.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Student roster list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = _students[index];
              return _buildStudentTile(student);
            },
          ),
          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmAllBoarded,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.directions_bus, color: Colors.white),
              label: const Text(
                'Confirm All Boarded',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(Student student) {
    Color borderColor;
    Widget statusWidget;

    switch (student.status) {
      case StudentStatus.boarded:
        borderColor = AppColors.successGreen;
        statusWidget = const Icon(
          Icons.check_circle,
          color: AppColors.successGreen,
          size: 26,
        );
        break;
      case StudentStatus.pending:
        borderColor = AppColors.outlineVariant;
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Pending',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        );
        break;
      case StudentStatus.alert:
        borderColor = AppColors.alertOrange;
        statusWidget = ElevatedButton(
          onPressed: () => _overrideStudent(student),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.alertOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Override',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: student.status == StudentStatus.alert
            ? AppColors.errorContainer.withOpacity(0.3)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHighest,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                ),
                Text(
                  '${student.grade} • ${student.seat}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          statusWidget,
        ],
      ),
    );
  }
}
