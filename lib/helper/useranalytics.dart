import 'package:appsflyer_sdk/appsflyer_sdk.dart';

class UserAnalytics {
  static late AppsflyerSdk appsflyerSdk;
  static String? _currentUserId;

  // Initialize at app startup
  static Future<void> initialize() async {
    Map<String, dynamic> appsFlyerOptions = {
      "afDevKey": "WPSQEEUZCLkr4F6bD3CS8Q",
      "afAppId": "YOUR_APP_ID", // iOS App ID (not needed for Android)
      "isDebug": true, // Set to false in production
    };
    
    appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
    await appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
  }

  // Track user login
  static void trackUserLogin(String email) {
    // Store the user ID for future reference
    _currentUserId = email;
    
    // Set Customer User ID in AppsFlyer
    appsflyerSdk.setCustomerUserId(email);
    
    // Track the login event with user properties
    Map<String, dynamic> eventValues = {
      'email': email,
      'login_time': DateTime.now().toIso8601String(),
      'button_name': 'Login Button',
      'screen': 'Login Screen',
    };
    
    appsflyerSdk.logEvent("user_login", eventValues);
  }
  
  // Track user logout
  static void trackUserLogout() {
    if (_currentUserId != null) {
      // Track the logout event with user properties
      Map<String, dynamic> eventValues = {
        'email': _currentUserId,
        'logout_time': DateTime.now().toIso8601String(),
      };
      
      appsflyerSdk.logEvent("user_logout", eventValues);
      
      // Reset the user ID in AppsFlyer
      appsflyerSdk.anonymizeUser(true);
      _currentUserId = null;
    }
  }
  
  // Track user action with user context
  static void trackUserAction(String action, Map<String, dynamic> properties) {
    if (_currentUserId == null) {
      // If no user is logged in, we might want to still track but note it's anonymous
      properties['is_anonymous'] = true;
    } else {
      // Add user context to all events
      properties['user_email'] = _currentUserId;
    }
    
    // Add timestamp to all events
    properties['timestamp'] = DateTime.now().toIso8601String();
    
    // Normalize action name
    String normalizedAction = action
        .toLowerCase()
        .replaceAll(' ', '_');
    
    // Log the event with AppsFlyer
    appsflyerSdk.logEvent(normalizedAction, properties);
  }

  // Additional user-specific tracking methods
  static void trackScreenView(String screenName) {
    Map<String, dynamic> properties = {
      'screen_name': screenName,
      'view_time': DateTime.now().toIso8601String(),
    };
    
    if (_currentUserId != null) {
      properties['user_email'] = _currentUserId;
    }
    
    appsflyerSdk.logEvent("screen_view", properties);
  }
  
  static void trackButtonClick(String buttonName, String screenName) {
    Map<String, dynamic> properties = {
      'button_name': buttonName,
      'screen': screenName,
    };
    
    trackUserAction('button_click', properties);
  }
  
  static void trackAPIRequest(String endpoint, String method, Map<String, dynamic> params) {
    Map<String, dynamic> properties = {
      'endpoint': endpoint,
      'method': method,
      'parameters': params.toString(),
    };
    
    trackUserAction('api_request', properties);
  }
  
  static void trackAPIResponse(String endpoint, int statusCode, String responseBody) {
    Map<String, dynamic> properties = {
      'endpoint': endpoint,
      'status_code': statusCode,
      'response': responseBody,
    };
    
    trackUserAction('api_response', properties);
  }
}