import '../repository/mosque.dart';

String mosqueMarkerKey(Mosque mosque) =>
    mosque.osmId ?? '${mosque.latitude}:${mosque.longitude}:${mosque.name}';
Map<String, Object> mosqueMarkerPayload(Mosque mosque) => {
  'mosqueKey': mosqueMarkerKey(mosque),
};
