import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'device_context_data.dart';

// --- CONFIGURATION CLASSES ---

/// Configuration for fetching static or slowly-changing hardware data.
class HardwareConfig {
  final bool deviceInfo;
  final bool batteryStatus;
  final bool instantElectricalDraw;
  final bool thermalState;
  final bool batteryHealth;

  const HardwareConfig({
    this.deviceInfo = true,
    this.batteryStatus = true,
    this.instantElectricalDraw = true,
    this.thermalState = true,
    this.batteryHealth = true,
  });
}

/// Configuration for fetching instant, single-shot sensor data.
class InstantSensorsConfig {
  final bool ambientLight;
  final bool location;
  final bool motionAndPosture;
  final bool aiActivityPrediction;

  const InstantSensorsConfig({
    this.ambientLight = true,
    this.location = true,
    this.motionAndPosture = true,
    this.aiActivityPrediction = true,
  });
}

/// Configuration for high-frequency continuous sampling over a time window.
class ContinuousSamplingConfig {
  /// How long the native engine should sample data before calculating the mean.
  final Duration window;

  /// The frequency of data collection (e.g., 20Hz means 20 reads per second).
  final int samplingRateHz;

  /// Calculates the average milliAmp draw over the time window.
  final bool averageElectricalDraw;

  /// Determines if the device was generally "Moving" or "Still" over the window,
  /// and calculates mean Acceleration (X, Y, Z).
  final bool averageMotionState;

  /// Calculates the average ambient light (lux) over the time window.
  final bool averageAmbientLight;

  const ContinuousSamplingConfig({
    required this.window,
    this.samplingRateHz = 20,
    this.averageElectricalDraw = false,
    this.averageMotionState = false,
    this.averageAmbientLight = false,
  });
}

// --- MAIN API ---

/// Main entry point for fetching hardware and environmental context data.
class DeviceContext {
  static const MethodChannel _channel = MethodChannel(
    'max.device.collector/context',
  );

  /// Fetches comprehensive context data from the device's hardware sensors.
  ///
  /// Grouped into [HardwareConfig], [InstantSensorsConfig], and optional
  /// [ContinuousSamplingConfig] for total flexibility.
  static Future<DeviceContextData> getSensorData({
    HardwareConfig hardware = const HardwareConfig(),
    InstantSensorsConfig instantSensors = const InstantSensorsConfig(),
    ContinuousSamplingConfig? continuousSampling,
  }) async {
    final Map<String, dynamic> collectedData = {};

    try {
      // 1. Map the beautiful Dart objects back to the Native Dictionary Keys
      final nativeArguments = {
        // Hardware
        'fetchDeviceInfo': hardware.deviceInfo,
        'fetchBasic': hardware.batteryStatus,
        'fetchElectrical': hardware.instantElectricalDraw,
        'fetchThermal': hardware.thermalState,
        'fetchHealth': hardware.batteryHealth,

        // Instant Sensors
        'fetchEnvironment': instantSensors.ambientLight,
        'fetchLocation': instantSensors.location,
        'fetchMotion': instantSensors.motionAndPosture,

        // Continuous Sampling (Defaults to 0/false if null)
        'samplingWindowSeconds': continuousSampling?.window.inSeconds ?? 0,
        'samplingHz': continuousSampling?.samplingRateHz ?? 20,
        'fetchMeanElectrical':
            continuousSampling?.averageElectricalDraw ?? false,
        'fetchMeanMotion': continuousSampling?.averageMotionState ?? false,
        'fetchMeanEnvironment':
            continuousSampling?.averageAmbientLight ?? false,
      };

      // 2. Initialize Concurrent AI Activity Stream (if requested)
      List<Activity> activitySamples = [];
      StreamSubscription<Activity>? activitySubscription;

      final isActivityRequested = instantSensors.aiActivityPrediction;
      final isSamplingEnabled =
          continuousSampling != null && continuousSampling.window.inSeconds > 0;

      if (isActivityRequested && isSamplingEnabled) {
        try {
          activitySubscription = FlutterActivityRecognition
              .instance
              .activityStream
              .listen((activity) => activitySamples.add(activity));
        } catch (e) {
          // Ignore: Permissions missing
        }
      }

      // 3. Await Native Hardware Data
      final nativeResult = await _channel.invokeMethod(
        'getSensorData',
        nativeArguments,
      );
      if (nativeResult != null) {
        collectedData.addAll(Map<String, dynamic>.from(nativeResult));
      }

      // 4. Process the Background AI Activity Data
      if (isActivityRequested) {
        if (isSamplingEnabled) {
          await activitySubscription?.cancel();
          _processActivitySamples(activitySamples, collectedData);
        } else {
          await _fetchInstantActivity(collectedData);
        }
      }
    } catch (e) {
      // Platform error handling
    }

    return DeviceContextData.fromMap(collectedData);
  }

  /// Processes a list of collected activity samples to find the most accurate prediction.
  static void _processActivitySamples(
    List<Activity> samples,
    Map<String, dynamic> dataMap,
  ) {
    if (samples.isNotEmpty) {
      final validActivities = samples
          .where((a) => a.type != ActivityType.UNKNOWN)
          .toList();
      final bestPrediction = validActivities.isNotEmpty
          ? validActivities.last
          : samples.last;

      dataMap['activityType'] = bestPrediction.type.toString().split('.').last;
      dataMap['activityConfidence'] = bestPrediction.confidence
          .toString()
          .split('.')
          .last;
    } else {
      dataMap['activityType'] = "UNKNOWN";
      dataMap['activityConfidence'] = "LOW";
    }
  }

  /// Fetches an instant activity prediction with a strict timeout.
  static Future<void> _fetchInstantActivity(
    Map<String, dynamic> dataMap,
  ) async {
    try {
      final activity = await FlutterActivityRecognition
          .instance
          .activityStream
          .first
          .timeout(
            const Duration(milliseconds: 5000),
            onTimeout: () =>
                Activity(ActivityType.UNKNOWN, ActivityConfidence.LOW),
          );
      dataMap['activityType'] = activity.type.toString().split('.').last;
      dataMap['activityConfidence'] = activity.confidence
          .toString()
          .split('.')
          .last;
    } catch (e) {
      dataMap['activityType'] = "UNKNOWN";
      dataMap['activityConfidence'] = "LOW";
    }
  }
}
