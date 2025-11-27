import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/profile_avatar.dart';
import 'profile_screen.dart';
import 'profile_viewer_screen.dart';

class EnrollmentRequestsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const EnrollmentRequestsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<EnrollmentRequestsScreen> createState() => _EnrollmentRequestsScreenState();
}

class _EnrollmentRequestsScreenState extends State<EnrollmentRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  Set<String> _processingRequests = {};
  bool _hasChanges = false; // Track if any changes were made

  @override
  void initState() {
    super.initState();
    _loadEnrollmentRequests();
  }

  Future<void> _loadEnrollmentRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await FirebaseService.getEnrollmentRequests(widget.courseId);
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveRequest(String studentId, String studentName) async {
    setState(() {
      _processingRequests.add(studentId);
    });

    try {
      print('Approving enrollment request for: $studentName ($studentId) in course: ${widget.courseId}');
      await FirebaseService.approveEnrollmentRequest(widget.courseId, studentId);
      print('Approval completed successfully');
      
      if (mounted) {
        setState(() {
          _hasChanges = true; // Mark that changes were made
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$studentName has been enrolled in the course'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the list
        _loadEnrollmentRequests();
      }
    } catch (e) {
      print('Error in _approveRequest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingRequests.remove(studentId);
        });
      }
    }
  }

  Future<void> _rejectRequest(String studentId, String studentName) async {
    setState(() {
      _processingRequests.add(studentId);
    });

    try {
      await FirebaseService.rejectEnrollmentRequest(widget.courseId, studentId);
      
      if (mounted) {
        setState(() {
          _hasChanges = true; // Mark that changes were made
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enrollment request from $studentName has been rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        // Refresh the list
        _loadEnrollmentRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingRequests.remove(studentId);
        });
      }
    }
  }

  void _showApproveConfirmation(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Approve Enrollment',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          'Approve enrollment for $studentName?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _approveRequest(studentId, studentName);
            },
            child: Text(
              'Approve',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Reject Enrollment',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          'Reject enrollment request from $studentName?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRequest(studentId, studentName);
            },
            child: Text(
              'Reject',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrollment Requests',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.courseTitle,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadEnrollmentRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      return _buildRequestCard(request);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Requests',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enrollment requests will appear here',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final studentId = request['studentId'] as String;
    final studentName = request['studentName'] as String? ?? 'Unknown Student';
    final rollNumber = request['rollNumber'] as String? ?? 'N/A';
    final studentEmail = request['studentEmail'] as String? ?? '';
    final profileIconIndex = request['profileIconIndex'] as int? ?? 0;
    final isProcessing = _processingRequests.contains(studentId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileViewerScreen(
                    userProfile: UserProfile(
                      name: studentName,
                      username: '@${rollNumber.toLowerCase()}',
                      major: request['major'] ?? 'Not specified',
                      age: request['age'] ?? '',
                      rollNumber: rollNumber,
                      phoneNumber: request['phoneNumber'] ?? '',
                      email: studentEmail,
                      semester: request['semester'] ?? 'Not specified',
                      cgpa: request['cgpa'] ?? 'N/A',
                      profileIconIndex: profileIconIndex,
                    ),
                  ),
                ),
              );
            },
            child: Row(
            children: [
              ProfileAvatar(
                iconIndex: profileIconIndex,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll: $rollNumber',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
          if (studentEmail.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    studentEmail,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _showRejectConfirmation(studentId, studentName),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close, size: 18),
                  label: Text(
                    'Reject',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _showApproveConfirmation(studentId, studentName),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    'Approve',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
