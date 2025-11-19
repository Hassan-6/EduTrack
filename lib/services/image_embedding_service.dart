import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class CameraOverlayData {
  final String address;
  final String coordinates;
  final String altitude;
  final String heading;
  final String localTime;
  final String gmtTime;
  final String date;

  CameraOverlayData({
    required this.address,
    required this.coordinates,
    required this.altitude,
    required this.heading,
    required this.localTime,
    required this.gmtTime,
    required this.date,
  });

  /// Convert overlay data to a map for metadata or storage
  Map<String, String> toMap() {
    return {
      'address': address,
      'coordinates': coordinates,
      'altitude': altitude,
      'heading': heading,
      'localTime': localTime,
      'gmtTime': gmtTime,
      'date': date,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get formatted overlay text
  String getFormattedText() {
    return '''$address
$coordinates | $altitude
$heading | $localTime / GMT $gmtTime
$date''';
  }
}

class ImageEmbeddingService {
  /// Process and return image bytes (currently just reads the image)
  /// In production, you would use a more advanced image processing library
  /// to actually embed text onto the image
  static Future<Uint8List?> embedOverlayData(
    String imagePath,
    CameraOverlayData overlayData,
  ) async {
    try {
      // Read image file
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        print('Image file not found: $imagePath');
        return null;
      }

      final imageBytes = await imageFile.readAsBytes();
      
      // In this simplified version, we return the original image bytes
      // The overlay is already shown in the UI during capture
      // For production text embedding, consider using:
      // - flutter_image_compress with text overlay
      // - native platform channels for image processing
      // - Firebase ML Kit for advanced image processing
      
      return imageBytes;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  /// Get overlay text for display or logging
  static String buildOverlayText(CameraOverlayData data) {
    return data.getFormattedText();
  }

  /// Format time for display
  static String formatLocalTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  /// Format GMT time for display
  static String formatGMTTime(DateTime dateTime) {
    final utcTime = dateTime.toUtc();
    return DateFormat('HH:mm:ss').format(utcTime);
  }

  /// Format date for display
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// Save overlay metadata to a JSON file alongside the image
  static Future<bool> saveOverlayMetadata(
    String imagePath,
    CameraOverlayData overlayData,
  ) async {
    try {
      final metadataPath = imagePath.replaceAll('.jpg', '_metadata.txt');
      final metadataFile = File(metadataPath);
      
      final metadata = '''CAMERA LOCATION DATA
=====================================
Address: ${overlayData.address}
GPS: ${overlayData.coordinates}
Altitude: ${overlayData.altitude}
Heading: ${overlayData.heading}
Local Time: ${overlayData.localTime}
GMT Time: ${overlayData.gmtTime}
Date: ${overlayData.date}
Captured: ${DateTime.now().toIso8601String()}
=====================================''';

      await metadataFile.writeAsString(metadata);
      print('Metadata saved to: $metadataPath');
      return true;
    } catch (e) {
      print('Error saving metadata: $e');
      return false;
    }
  }
}
