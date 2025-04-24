
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

class AnalyticsHelper {
  static late AppsflyerSdk _appsflyerSdk;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    Map<String, dynamic> appsFlyerOptions = {
      "afDevKey": "WPSQEEUZCLkr4F6bD3CS8Q",
      "afAppId": "YOUR_APP_ID", // iOS App ID (not needed for Android)
      "isDebug": true, // Set to false in production
    };

    _appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
    await _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    
    _initialized = true;
  }

  // Log a custom event
  static Future<void> logEvent(String eventName, [Map<String, dynamic>? props]) async {
    if (!_initialized) await initialize();
    await _appsflyerSdk.logEvent(eventName, props ?? {});
  }

  // Set user ID (equivalent to Mixpanel identify)
  static Future<void> setCustomerUserId(String email) async {
    if (!_initialized) await initialize();
    _appsflyerSdk.setCustomerUserId(email);
  }

  // Reset user (equivalent to Mixpanel reset)
  static Future<void> resetUser() async {
    if (!_initialized) await initialize();
     _appsflyerSdk.stop(true);
     _appsflyerSdk.anonymizeUser(true);
  }
}

Future<void> identifyUser(String email) async {
  await AnalyticsHelper.setCustomerUserId(email);
}
