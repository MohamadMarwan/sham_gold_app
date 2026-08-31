enum TrackingStatus { notDetermined, restricted, denied, authorized, notSupported }

class AppTrackingTransparency {
  static Future<TrackingStatus> get trackingAuthorizationStatus async => TrackingStatus.notSupported;
  static Future<TrackingStatus> requestTrackingAuthorization() async => TrackingStatus.notSupported;
}
