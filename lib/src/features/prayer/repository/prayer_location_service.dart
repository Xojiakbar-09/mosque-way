import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/service/location_service.dart';
import 'prayer_location.dart';

class PrayerLocationService {
  Future<PrayerLocation> current() async {
    final status = await const LocationService().checkPermission();
    if (status != LocationPermissionStatus.granted) {
      throw const LocationUnavailable();
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    Placemark? place;
    try {
      place =
          (await Geocoding()
                  .placemarkFromCoordinates(
                    position.latitude,
                    position.longitude,
                  )
                  .timeout(const Duration(seconds: 8)))
              .firstOrNull;
    } catch (_) {
      /* A geocoder failure must not prevent coordinate-based timing. */
    }
    return PrayerLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      city: place?.locality ?? place?.administrativeArea ?? '',
      country: place?.country ?? '',
      countryCode: place?.isoCountryCode ?? '',
    );
  }
}

class LocationUnavailable implements Exception {
  const LocationUnavailable();
}
