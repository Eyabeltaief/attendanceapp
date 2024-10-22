import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geocoding/geocoding.dart';

class LocationService {
  loc.Location _location = loc.Location();

  Future<void> initialize() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print("Location services are disabled.");
        return;
      }
    }

    // Request location permissions using permission_handler
    var status = await perm.Permission.location.status;
    print("Initial permission status: $status");
    if (status.isDenied) {
      if (await perm.Permission.location.request().isGranted) {
        print("Location permission granted.");
      } else {
        print("Location permission denied.");
        return;
      }
    } else if (status.isPermanentlyDenied) {
      print("Location permission permanently denied.");
      return;
    } else {
      print("Location permission already granted.");
    }
  }

  Future<double?> getLongitude() async {
    try {
      loc.LocationData locationData = await _location.getLocation();
      return locationData.longitude;
    } catch (e) {
      print("Failed to get longitude: $e");
      return null;
    }
  }

  Future<double?> getLatitude() async {
    try {
      loc.LocationData locationData = await _location.getLocation();
      return locationData.latitude;
    } catch (e) {
      print("Failed to get latitude: $e");
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.locality}, ${place.country}";
      } else {
        return "No address found";
      }
    } catch (e) {
      print("Failed to get address: $e");
      return "Failed to get address";
    }
  }
}
