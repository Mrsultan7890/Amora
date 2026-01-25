import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  
  LocationService._();
  
  Position? _currentPosition;
  bool _locationFetched = false;
  
  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission.isGranted;
  }
  
  Future<Position?> getCurrentLocation() async {
    if (_locationFetched && _currentPosition != null) {
      return _currentPosition;
    }
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }
      
      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _locationFetched = true;
      
      // Update user location in backend
      if (_currentPosition != null) {
        await _updateUserLocation(_currentPosition!);
      }
      
      print('Location fetched: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      return _currentPosition;
      
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
  
  Future<void> _updateUserLocation(Position position) async {
    try {
      await ApiService.instance.updateProfile({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      print('Location updated in backend');
    } catch (e) {
      print('Failed to update location in backend: $e');
    }
  }
  
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }
  
  Future<void> initializeLocation() async {
    await getCurrentLocation();
  }
}