import Flutter
import UIKit
import UnityAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Initialize Unity Ads with Game ID from backend (placeholder, will be set via MethodChannel later)
    // UnityAds.initialize("6103432", testMode: false)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
