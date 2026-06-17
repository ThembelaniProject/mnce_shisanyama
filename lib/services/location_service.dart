import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<String> getCurrentAddress() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return "Location disabled";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "Permission denied";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return "Permission blocked";
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = place.street?? '';
        final area = place.subLocality?? place.locality?? '';
        
        if (street.isNotEmpty && area.isNotEmpty) {
          return "$area, $street";
        } else if (area.isNotEmpty) {
          return area;
        } else {
          return place.locality?? "Unknown location";
        }
      }
      return "Location not found";
    } catch (e) {
      return "Soweto"; // fallback
    }
  }
}