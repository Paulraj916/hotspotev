import 'package:hotspot/main.dart';

class AnalyticsHelper {
  static void logEvent(String event, [Map<String, dynamic>? props]) {
    mixpanel.track(event, properties: props ?? {});
  }
}
