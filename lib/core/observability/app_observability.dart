import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central, privacy-safe production telemetry.
///
/// Financial values, free-form text, record IDs, email addresses, and Firebase
/// user IDs must never be passed to this service.
class AppObservability {
  AppObservability._();

  static final AppObservability instance = AppObservability._();
  static const _enabledPreference = 'diagnostics_and_analytics_enabled';

  bool _enabled = false;
  bool _preferenceEnabled = true;
  bool _initialized = false;

  bool get enabled => _enabled;
  bool get preferenceEnabled => _preferenceEnabled;

  bool get _supportsFirebaseTelemetry =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  late final NavigatorObserver navigatorObserver =
      _ObservabilityNavigatorObserver(this);

  Future<void> initialize() async {
    if (_initialized) return;
    final preferences = await SharedPreferences.getInstance();
    _preferenceEnabled = preferences.getBool(_enabledPreference) ?? true;
    _enabled = kReleaseMode && _preferenceEnabled;
    _initialized = true;
    await _applyCollectionState();
  }

  Future<void> setEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledPreference, value);
    _preferenceEnabled = value;
    _enabled = kReleaseMode && value;
    await _applyCollectionState();
  }

  Future<void> _applyCollectionState() async {
    if (!_supportsFirebaseTelemetry) return;
    await Future.wait([
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(_enabled),
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(_enabled),
      FirebasePerformance.instance.setPerformanceCollectionEnabled(_enabled),
    ]);
  }

  void installGlobalErrorHandlers() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterHandler?.call(details);
      if (previousFlutterHandler == null) FlutterError.presentError(details);
      unawaited(recordFlutterError(details, fatal: true));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Unhandled asynchronous error: $error');
        debugPrintStack(stackTrace: stack);
      }
      unawaited(recordError(error, stack, fatal: true));
      return true;
    };
  }

  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    if (!_enabled || !_supportsFirebaseTelemetry) return;
    try {
      if (fatal) {
        await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        await FirebaseCrashlytics.instance.recordFlutterError(details);
      }
    } catch (_) {}
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!_enabled || !_supportsFirebaseTelemetry) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: fatal,
        reason: reason,
      );
    } catch (_) {}
  }

  Future<void> setAuthenticationState({required bool signedIn}) async {
    if (!_enabled || !_supportsFirebaseTelemetry) return;
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'authentication_state',
        value: signedIn ? 'signed_in' : 'signed_out',
      );
    } catch (_) {}
  }

  Future<void> _logScreen(Route<dynamic>? route) async {
    if (!_enabled || !_supportsFirebaseTelemetry) return;
    final name = route?.settings.name;
    if (name == null || !_safeRoute.hasMatch(name)) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(screenName: name);
    } catch (_) {}
  }

  Future<void> logFinanceAction({
    required String module,
    required String action,
    String? result,
  }) async {
    if (!_enabled || !_supportsFirebaseTelemetry) return;
    assert(_safeToken.hasMatch(module) && _safeToken.hasMatch(action));
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'finance_action',
        parameters: {
          'module': module,
          'action': action,
          'result': ?result,
        },
      );
    } catch (_) {}
  }

  Future<T> trace<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String> attributes = const {},
  }) async {
    if (!_enabled || !_supportsFirebaseTelemetry) return operation();

    Trace? performanceTrace;
    try {
      performanceTrace = FirebasePerformance.instance.newTrace(name);
      for (final entry in attributes.entries) {
        performanceTrace.putAttribute(entry.key, entry.value);
      }
      await performanceTrace.start();
    } catch (_) {
      performanceTrace = null;
    }

    try {
      final result = await operation();
      performanceTrace?.putAttribute('result', 'success');
      return result;
    } catch (error, stack) {
      performanceTrace?.putAttribute('result', 'failure');
      unawaited(recordError(error, stack, reason: name));
      rethrow;
    } finally {
      try {
        await performanceTrace?.stop();
      } catch (_) {}
    }
  }

  static final RegExp _safeToken = RegExp(r'^[a-z][a-z0-9_]{1,39}$');
  static final RegExp _safeRoute = RegExp(r'^/[a-z][a-z0-9_/-]{0,79}$');
}

class _ObservabilityNavigatorObserver extends NavigatorObserver {
  _ObservabilityNavigatorObserver(this.observability);

  final AppObservability observability;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(observability._logScreen(route));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    unawaited(observability._logScreen(newRoute));
  }
}
