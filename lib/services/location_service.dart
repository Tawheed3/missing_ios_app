// lib/services/location_service.dart
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';

class LocationService {
  // ========== دالة مساعدة للحصول على النصوص المترجمة ==========
  String _getLocalizedString(String key) {
    // هذه دالة مساعدة، سيتم استبدالها بالنص الفعلي من التطبيق
    // عند استخدامها في الشاشات، سنمرر context
    return key;
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(_getLocalizedString('locationServiceDisabled'));
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(_getLocalizedString('locationPermissionDenied'));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(_getLocalizedString('locationPermissionDeniedForever'));
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> getPlaceName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return _getLocalizedString('unknownLocation');
    } catch (e) {
      return _getLocalizedString('unknownLocation');
    }
  }

  Future<double> calculateDistance(GeoPoint point1, GeoPoint point2) async {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
}