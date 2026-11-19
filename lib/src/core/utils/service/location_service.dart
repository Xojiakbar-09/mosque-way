import 'package:geolocator/geolocator.dart';

/// Joylashuvga ruxsat holati.
enum LocationPermissionStatus {
  /// GPS yoqilgan va ruxsat berilgan.
  granted,

  /// Telefonda GPS (joylashuv xizmati) o'chirilgan.
  serviceDisabled,

  /// Ruxsat berilmagan.
  denied,

  /// Ruxsat butunlay rad etilgan (sozlamalardan yoqish kerak).
  deniedForever,
}

/// Joylashuvga ruxsat berilgan yoki yo'qligini aniqlaydi.
class LocationService {
  const LocationService();

  /// GPS yoqilganini va ruxsat berilganini aniqlaydi.
  /// Kerak bo'lsa foydalanuvchidan ruxsat so'raydi.
  Future<LocationPermissionStatus> checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionStatus.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationPermissionStatus.denied;
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }
}
