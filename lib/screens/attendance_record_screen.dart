import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/course_model.dart';
import 'profile_screen.dart';
import 'profile_viewer_screen.dart';
import '../services/firebase_service.dart';

class AttendanceRecordScreen extends StatelessWidget {
  final Course course;
  final Map<String, dynamic> record;

  const AttendanceRecordScreen({
    super.key,
    required this.course,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final students = record['students'] as List<dynamic>? ?? [];
    final present = record['present'] ?? 0;
    final total = record['total'] ?? 0;
    final date = record['date'] ?? 'Unknown';
    final percentage = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Attendance Details',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Session info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  spreadRadius: 0,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course name
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: course.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school,
                        color: course.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // Attendance statistics
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Present',
                        present.toString(),
                        Icons.check_circle,
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total',
                        total.toString(),
                        Icons.people,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Rate',
                        '$percentage%',
                        Icons.pie_chart,
                        _getPercentageColor(double.parse(percentage)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Students list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Present Students',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: course.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${students.length} student${students.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    color: course.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Students list
          if (students.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No students marked present',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...students.asMap().entries.map((entry) {
              final index = entry.key;
              final student = entry.value as Map<String, dynamic>;
              return _buildStudentCard(
                context,
                student,
                index + 1,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Map<String, dynamic> student, int index) {
    final name = student['name'] ?? 'Unknown';
    final rollNumber = student['rollNumber'] ?? 'N/A';
    final photoURL = student['photoURL'] ?? '';
    final studentId = student['studentId'] ?? student['id'];
    
    return InkWell(
      onTap: studentId != null
          ? () async {
              try {
                final profile = await FirebaseService.getUserProfile(studentId);
                if (profile != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileViewerScreen(
                        userProfile: UserProfile(
                          name: profile['name'] ?? name,
                          username: '@${(profile['rollNumber'] ?? rollNumber).toLowerCase()}',
                          major: profile['major'] ?? 'Not specified',
                          age: profile['age'] ?? '',
                          rollNumber: profile['rollNumber'] ?? rollNumber,
                          phoneNumber: profile['phoneNumber'] ?? '',
                          email: profile['email'] ?? '',
                          semester: profile['semester'] ?? 'Not specified',
                          cgpa: profile['cgpa'] ?? 'N/A',
                          profileIconIndex: profile['profileIconIndex'] ?? 0,
                        ),
                      ),
                    ),
                  );
                }
              } catch (e) {
                print('Error loading student profile: $e');
                if (photoURL.isNotEmpty && context.mounted) {
                  _showStudentPhoto(context, name, photoURL);
                }
              }
            }
          : (photoURL.isNotEmpty ? () => _showStudentPhoto(context, name, photoURL) : null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            // Serial number
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: course.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: GoogleFonts.inter(
                    color: course.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rollNumber,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Photo icon if available
            if (photoURL.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_camera,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            const SizedBox(width: 8),
            // Check icon
            Icon(
              Icons.check_circle,
              color: const Color(0xFF10B981),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentPhoto(BuildContext context, String studentName, String photoURL) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photoURL,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load photo',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) {
      return const Color(0xFF10B981); // Green
    } else if (percentage >= 50) {
      return const Color(0xFFF59E0B); // Orange
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }
}
