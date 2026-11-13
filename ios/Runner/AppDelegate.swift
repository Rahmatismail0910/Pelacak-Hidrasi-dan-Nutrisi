import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  UNUserNotificationCenter.current().delegate =
      self as? UNUserNotificationCenterDelegate

  return super.application(
    application,
    didFinishLaunchingWithOptions: launchOptions
  )
}
