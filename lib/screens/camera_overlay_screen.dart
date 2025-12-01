import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/camera_location_service.dart';
import '../services/compass_service.dart';
import '../services/image_embedding_service.dart';

class CameraOverlayScreen extends StatefulWidget {
  const CameraOverlayScreen({Key? key}) : super(key: key);

  @override
  State<CameraOverlayScreen> createState() => _CameraOverlayScreenState();
}

class _CameraOverlayScreenState extends State<CameraOverlayScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  
  CameraLocationData? _locationData;
  double _heading = 0;
  bool _isProcessing = false;
  String? _errorMessage;
  
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getLocationData();
    _startCompassListener();
    _requestStoragePermission();
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras![0], // Use back camera
          ResolutionPreset.max,
          enableAudio: false,
        );
        _initializeControllerFuture = _cameraController.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  /// Get location data
  Future<void> _getLocationData() async {
    try {
      final location = await CameraLocationService.getCurrentLocation();
      if (mounted && location != null) {
        setState(() {
          _locationData = location;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  /// Start listening to compass
  void _startCompassListener() {
    CompassService.getCompassHeading().listen((heading) {
      if (mounted) {
        setState(() {
          _heading = heading;
        });
      }
    });
  }

  /// Request storage permission
  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        print('Storage permission not granted');
      }
    }
  }

  /// Capture photo with overlay data
  Future<void> _capturePhoto() async {
    if (_isProcessing || _locationData == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      await _initializeControllerFuture;

      // Take picture
      final image = await _cameraController.takePicture();

      // Get current time
      final now = DateTime.now();

      // Create overlay data
      final overlayData = CameraOverlayData(
        address: _locationData!.address,
        coordinates: CameraLocationService.formatCoordinates(
          _locationData!.latitude,
          _locationData!.longitude,
        ),
        altitude: CameraLocationService.formatAltitude(_locationData!.altitude),
        heading: CompassService.formatHeading(_heading),
        localTime: ImageEmbeddingService.formatLocalTime(now),
        gmtTime: ImageEmbeddingService.formatGMTTime(now),
        date: ImageEmbeddingService.formatDate(now),
      );

      // Save overlay metadata
      await ImageEmbeddingService.saveOverlayMetadata(image.path, overlayData);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved successfully with location data!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Pop back after 1 second with photo path and location data
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop({
              'photoPath': image.path,
              'latitude': _locationData!.latitude,
              'longitude': _locationData!.longitude,
              'altitude': _locationData!.altitude,
              'address': _locationData!.address,
              'accuracy': _locationData!.accuracy,
            });
          }
        });
      }
    } catch (e) {
      print('Error capturing photo: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build overlay data display
  Widget _buildOverlay() {
    if (_locationData == null) {
      return Center(
        child: Text(
          'Loading location data...',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Semi-transparent black box with data at top
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address
              Text(
                _locationData!.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Coordinates, Altitude, Heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          CameraLocationService.formatCoordinates(
                            _locationData!.latitude,
                            _locationData!.longitude,
                          ),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Altitude',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          CameraLocationService.formatAltitude(
                            _locationData!.altitude,
                          ),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compass',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          CompassService.formatHeading(_heading),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Time and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Time',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          ImageEmbeddingService.formatLocalTime(DateTime.now()),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GMT Time',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          ImageEmbeddingService.formatGMTTime(DateTime.now()),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          ImageEmbeddingService.formatDate(DateTime.now()),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Error'),
        ),
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera with Location Data'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera preview
                CameraPreview(_cameraController),
                
                // Overlay with data
                _buildOverlay(),
                
                // Bottom controls
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _capturePhoto,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 32,
                              ),
                      ),
                    ),
                  ),
                ),
                
                // Back button
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.6),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
