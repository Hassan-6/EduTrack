import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class GPSCameraScreen extends StatefulWidget {
  const GPSCameraScreen({super.key});

  @override
  State<GPSCameraScreen> createState() => _GPSCameraScreenState();
}

class _GPSCameraScreenState extends State<GPSCameraScreen> {
  CameraController? _controller;
  Position? _currentLocation;
  String? _currentAddress;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    await _controller!.initialize();
    
    setState(() {
      _isCameraReady = true;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      
      setState(() {
        _currentLocation = position;
        _currentAddress = placemarks.isNotEmpty 
            ? "${placemarks[0].street}, ${placemarks[0].locality}"
            : "Location acquired";
      });
    } catch (e) {
      print("Location error: $e");
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraReady || _controller == null) return;

    try {
      // Capture the photo
      XFile imageFile = await _controller!.takePicture();
      
      // Return to attendance screen with verification data
      Navigator.pop(context, {
        'imagePath': imageFile.path,
        'location': _currentLocation,
        'address': _currentAddress,
        'verified': true,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print("Error taking photo: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with location info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: [
                      Text(
                        'Attendance Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentAddress ?? 'Getting location...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // For balance
                ],
              ),
            ),

            // Camera Preview
            Expanded(
              child: _isCameraReady && _controller != null
                  ? CameraPreview(_controller!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),

            // Capture Button
            Container(
              padding: const EdgeInsets.all(24),
              child: FloatingActionButton(
                onPressed: _capturePhoto,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}