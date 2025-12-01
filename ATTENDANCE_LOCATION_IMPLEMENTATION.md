# Attendance Location Data Implementation

## Overview
This document describes the implementation of location data capture and display for attendance records in the EduTrack application.

## Feature Description
When students capture a photo for attendance verification, the system now:
1. Captures their GPS location (latitude, longitude, altitude, address)
2. Stores this location data in Firebase alongside the photo
3. Allows instructors to view attendance history with location information for each student

## Implementation Details

### 1. Camera Overlay Screen (`camera_overlay_screen.dart`)
**Changes:**
- Modified `Navigator.pop()` to return a Map containing both photo path and location data
- Returns: `{'photoPath', 'latitude', 'longitude', 'altitude', 'address', 'accuracy'}`

**Before:**
```dart
Navigator.of(context).pop(image.path);
```

**After:**
```dart
Navigator.of(context).pop({
  'photoPath': image.path,
  'latitude': _locationData!.latitude,
  'longitude': _locationData!.longitude,
  'altitude': _locationData!.altitude,
  'address': _locationData!.address,
  'accuracy': _locationData!.accuracy,
});
```

### 2. Attendance Screen (`attendance_screen.dart`)
**Changes:**
- Added `_locationData` state variable to store location information
- Updated `_takePhoto()` to handle Map return value from camera
- Added timestamp to location data when captured
- Passes location data to Firebase service when submitting attendance

**Key Code:**
```dart
Map<String, dynamic>? _locationData;

// In _takePhoto():
if (result != null && result is Map<String, dynamic>) {
  setState(() {
    _isPhotoTaken = true;
    _capturedPhotoPath = result['photoPath'];
    _locationData = {
      'latitude': result['latitude'],
      'longitude': result['longitude'],
      'altitude': result['altitude'],
      'address': result['address'],
      'accuracy': result['accuracy'],
      'timestamp': DateTime.now().toIso8601String(),
    };
  });
}

// When submitting:
await FirebaseService.updateAttendancePhoto(
  courseId: verifiedCourseId,
  studentId: studentId,
  otp: enteredOtp,
  photoURL: photoURL,
  locationData: _locationData, // Pass location data
);
```

### 3. Firebase Service (`firebase_service.dart`)
**Changes:**
- Added optional `locationData` parameter to `updateAttendancePhoto()` method
- Stores location data in `studentLocations` map in Firestore (parallel to `studentPhotos`)

**Updated Method Signature:**
```dart
static Future<void> updateAttendancePhoto({
  required String courseId,
  required String studentId,
  required String otp,
  required String photoURL,
  Map<String, dynamic>? locationData, // NEW parameter
}) async {
  // ...
  Map<String, dynamic> updateData = {
    'studentPhotos.$studentId': photoURL,
  };
  
  if (locationData != null) {
    updateData['studentLocations.$studentId'] = locationData;
  }
  
  await sessionDoc.reference.update(updateData);
}
```

### 4. Instructor Attendance History Screen (`ins_attendance_history_screen.dart`)
**New File:** Complete screen for viewing attendance with location data

**Features:**
- Displays all attendance sessions for a course
- Shows verified students for each session
- Displays location information for each student:
  - Full address
  - GPS coordinates (latitude, longitude)
  - Location accuracy
  - Capture timestamp
- Allows viewing student photos in full-screen dialog
- Pull-to-refresh functionality

**UI Structure:**
```
Screen
├── AppBar (with refresh button)
└── ListView
    └── Card (per session)
        └── ExpansionTile
            ├── Session date and OTP
            ├── Student count
            └── Expanded: List of students
                └── ListTile (per student)
                    ├── Avatar
                    ├── Name
                    ├── Location info
                    │   ├── Address with icon
                    │   ├── Coordinates
                    │   ├── Accuracy
                    │   └── Timestamp
                    └── View Photo button
```

### 5. Instructor Course Detail Screen (`ins_course_detail_screen.dart`)
**Changes:**
- Added import for `InsAttendanceHistoryScreen`
- Added `_viewAttendanceWithLocations()` navigation method
- Added new button "View Attendance with Locations" with location icon

**Button Addition:**
```dart
Container(
  // ... styling ...
  child: InkWell(
    onTap: _viewAttendanceWithLocations,
    child: Row(
      children: [
        Icon(Icons.location_on, color: widget.course.color),
        const SizedBox(width: 8),
        Text('View Attendance with Locations'),
      ],
    ),
  ),
)
```

## Database Schema

### Firestore Collection: `attendanceSessions`
**Document Structure:**
```
{
  courseId: string,
  createdAt: timestamp,
  expiresAt: timestamp,
  otp: string,
  isActive: boolean,
  verifiedStudents: [studentId1, studentId2, ...],
  studentPhotos: {
    studentId1: photoURL1,
    studentId2: photoURL2,
    ...
  },
  studentLocations: {  // NEW FIELD
    studentId1: {
      latitude: double,
      longitude: double,
      altitude: double,
      address: string,
      accuracy: double,
      timestamp: string (ISO 8601)
    },
    studentId2: { ... },
    ...
  }
}
```

## User Flow

### Student Perspective:
1. Open attendance screen and enter OTP
2. Tap "Take Photo with Location"
3. Camera captures photo with GPS location overlay
4. Photo and location data are sent to Firebase
5. Student receives confirmation

### Instructor Perspective:
1. Navigate to course details
2. Tap "View Attendance with Locations"
3. View list of all attendance sessions
4. Expand a session to see verified students
5. View each student's:
   - Name and photo
   - Address where they were located
   - GPS coordinates
   - Location accuracy
   - Time of capture

## Technical Notes

### Location Data Format:
- **Latitude/Longitude**: Double precision (6 decimal places shown)
- **Altitude**: Meters above sea level
- **Address**: Reverse-geocoded string from coordinates
- **Accuracy**: GPS accuracy in meters
- **Timestamp**: ISO 8601 format (e.g., "2024-01-15T14:30:00.000Z")

### Privacy Considerations:
- Location data is only captured when student explicitly takes attendance photo
- Location is embedded in photo overlay (visible to student)
- Only instructors of the course can view location data
- Data is securely stored in Firestore with proper access rules

### Performance:
- Batch loading of student profiles to minimize Firestore reads
- Lazy loading of photos (only loaded when "View Photo" tapped)
- Caching of location data in memory while viewing history

## Testing Checklist
- [ ] Student can capture photo with location
- [ ] Location data appears in photo overlay
- [ ] Attendance submission includes location
- [ ] Location data stored in Firestore
- [ ] Instructor can access attendance history screen
- [ ] Location information displays correctly
- [ ] Photo viewer works properly
- [ ] Refresh functionality works
- [ ] Handles missing location data gracefully
- [ ] Handles missing student information gracefully

## Future Enhancements
- Map view showing all student locations for a session
- Export attendance with locations to CSV/Excel
- Location-based alerts (e.g., student too far from campus)
- Historical location tracking across sessions
- Geofencing for attendance validation
