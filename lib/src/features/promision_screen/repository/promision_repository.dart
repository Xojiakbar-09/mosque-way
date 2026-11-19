import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps/src/core/utils/service/location_service.dart';

/// Geocoding natijasi: foydalanuvchi turgan davlat va shahar.
class PlaceInfo {
  const PlaceInfo({required this.country, required this.city});

  /// Davlat nomi.
  final String country;

  /// Shahar (yoki viloyat) nomi.
  final String city;
}

/// Promision ekrani ortidagi ma'lumot qatlami:
/// ruxsatni tekshirish, joriy lokatsiya va geocoding.
abstract class PromisionRepository {
  /// Joylashuvga ruxsat holatini aniqlaydi (kerak bo'lsa so'raydi).
  Future<LocationPermissionStatus> checkPermission();

  /// Foydalanuvchining joriy koordinatasini oladi.
  Future<Position> getCurrentPosition();

  /// Koordinatadan davlat va shahar nomini aniqlaydi.
  Future<PlaceInfo> getPlaceInfo(Position position);
}

class PromisionRepositoryImpl implements PromisionRepository {
  PromisionRepositoryImpl();

  final LocationService _locationService = const LocationService();
  final Geocoding _geocoding = Geocoding();

  @override
  Future<LocationPermissionStatus> checkPermission() =>
      _locationService.checkPermission();

  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );

  @override
  Future<PlaceInfo> getPlaceInfo(Position position) async {
    final placemarks = await _geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      return const PlaceInfo(country: "", city: "");
    }

    final place = placemarks.first;

    return PlaceInfo(
      country: place.country ?? "",
      city: place.locality ?? place.subAdministrativeArea ?? "",
    );
  }
}
