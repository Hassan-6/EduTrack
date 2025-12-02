import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Screen for instructors to view attendance history with location data
class InsAttendanceHistoryScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const InsAttendanceHistoryScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<InsAttendanceHistoryScreen> createState() => _InsAttendanceHistoryScreenState();
}

class _InsAttendanceHistoryScreenState extends State<InsAttendanceHistoryScreen> {
  final _dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
  List<Map<String, dynamic>> _attendanceSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceSessions();
  }

  /// Load all attendance sessions for this course
  Future<void> _loadAttendanceSessions() async {
    try {
      setState(() => _isLoading = true);
      
      // Query without orderBy to avoid permission/index issues
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('attendanceSessions')
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      List<Map<String, dynamic>> sessions = [];
      
      for (var sessionDoc in sessionsSnapshot.docs) {
        final data = sessionDoc.data();
        final verifiedStudents = List<String>.from(data['verifiedStudents'] ?? []);
        final studentPhotos = Map<String, String>.from(data['studentPhotos'] ?? {});
        final studentLocations = Map<String, dynamic>.from(data['studentLocations'] ?? {});
        
        // Get student names
        Map<String, String> studentNames = {};
        for (var studentId in verifiedStudents) {
          try {
            final studentDoc = await FirebaseFirestore.instance
                .collection('students')
                .doc(studentId)
                .get();
            if (studentDoc.exists) {
              studentNames[studentId] = studentDoc.data()?['name'] ?? 'Unknown Student';
            }
          } catch (e) {
            print('Error loading student name: $e');
            studentNames[studentId] = 'Unknown Student';
          }
        }

        sessions.add({
          'sessionId': sessionDoc.id,
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
          'verifiedStudents': verifiedStudents,
          'studentPhotos': studentPhotos,
          'studentLocations': studentLocations,
          'studentNames': studentNames,
          'otp': data['otp'] ?? '',
        });
      }

      // Sort sessions by date in memory (descending - newest first)
      sessions.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

      setState(() {
        _attendanceSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attendance sessions: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance History'),
            Text(
              widget.courseName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceSessions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceSessions.isEmpty
              ? const Center(
                  child: Text(
                    'No attendance records found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _attendanceSessions.length,
                  itemBuilder: (context, index) {
                    final session = _attendanceSessions[index];
                    return _buildSessionCard(session);
                  },
                ),
    );
  }

  /// Build a card for each attendance session
  Widget _buildSessionCard(Map<String, dynamic> session) {
    final createdAt = session['createdAt'] as DateTime;
    final verifiedStudents = session['verifiedStudents'] as List<String>;
    final studentPhotos = session['studentPhotos'] as Map<String, String>;
    final studentLocations = session['studentLocations'] as Map<String, dynamic>;
    final studentNames = session['studentNames'] as Map<String, String>;
    final otp = session['otp'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blue),
        title: Text(
          _dateFormat.format(createdAt),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${verifiedStudents.length} students verified | OTP: $otp'),
        children: verifiedStudents.map((studentId) {
          final studentName = studentNames[studentId] ?? 'Unknown Student';
          final photoURL = studentPhotos[studentId];
          final locationData = studentLocations[studentId] as Map<String, dynamic>?;

          return _buildStudentTile(
            studentId: studentId,
            studentName: studentName,
            photoURL: photoURL,
            locationData: locationData,
          );
        }).toList(),
      ),
    );
  }

  /// Build a tile for each student in the session
  Widget _buildStudentTile({
    required String studentId,
    required String studentName,
    String? photoURL,
    Map<String, dynamic>? locationData,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (locationData != null) ...[
              _buildLocationInfo(locationData),
              const SizedBox(height: 4),
            ] else
              const Text(
                'No location data',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            if (photoURL != null)
              TextButton.icon(
                onPressed: () => _showPhotoDialog(studentName, photoURL),
                icon: const Icon(Icons.photo, size: 16),
                label: const Text('View Photo'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                ),
              )
            else
              const Text(
                'No photo available',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  /// Build location information widget
  Widget _buildLocationInfo(Map<String, dynamic> locationData) {
    final address = locationData['address'] as String?;
    final latitude = locationData['latitude'] as double?;
    final longitude = locationData['longitude'] as double?;
    final accuracy = locationData['accuracy'] as double?;
    final heading = locationData['heading'] as double?;
    final timestamp = locationData['timestamp'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                address ?? 'Address not available',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (latitude != null && longitude != null) ...[
          const SizedBox(height: 2),
          Text(
            'Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
        if (accuracy != null) ...[
          const SizedBox(height: 2),
          Text(
            'Accuracy: ${accuracy.toStringAsFixed(1)}m',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
        if (heading != null) ...[
          const SizedBox(height: 2),
          Text(
            'Heading: ${heading.toStringAsFixed(0)}° ${_getCompassDirection(heading)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
        if (timestamp != null) ...[
          const SizedBox(height: 2),
          Text(
            'Captured: ${_formatTimestamp(timestamp)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  /// Format timestamp string
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  /// Get compass direction from heading (N, NE, E, SE, S, SW, W, NW)
  String _getCompassDirection(double heading) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    
    // Normalize heading to 0-360
    final normalizedHeading = ((heading % 360) + 360) % 360;
    
    // Each direction covers 22.5 degrees (360 / 16)
    final index = ((normalizedHeading + 11.25) / 22.5).toInt() % 16;
    return directions[index];
  }

  /// Show photo in a dialog
  void _showPhotoDialog(String studentName, String photoURL) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(studentName),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  photoURL,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Failed to load image'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
