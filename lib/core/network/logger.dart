import 'dart:developer' as developer;
import '../config/app_config.dart';

class AppLogger {
  static void log(String message, {String name = 'App'}) {
    if (AppConfig.enableLogging) {
      developer.log(message, name: name);
    }
  }

  static void info(String message) {
    log('INFO: $message', name: 'AppLogger');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConfig.enableLogging) {
      developer.log(
        'ERROR: $message',
        name: 'AppLogger',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void analyticsEvent(
    String eventName, [
    Map<String, dynamic>? parameters,
  ]) {
    if (AppConfig.enableLogging) {
      // Stub for actual analytics plugin in production (e.g. FirebaseAnalytics.instance.logEvent)
      developer.log(
        'ANALYTICS EVENT: $eventName | params: $parameters',
        name: 'Analytics',
      );
    }
  }
}
