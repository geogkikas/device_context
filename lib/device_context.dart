import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'device_context_data.dart';

class DeviceContext {
  static const MethodChannel _channel = MethodChannel(
    'max.device.collector/context',
  );

  /// Fetches context data, returning a strongly-typed DeviceContextData object.
  /// NOTE: You MUST request required permissions (Location, Activity Recognition)
  /// in your host app before calling this method if you want those fields populated.
  static Future<DeviceContextData> getSensorData({
    bool fetchDeviceInfo = true,
    bool fetchBasic = true,
    bool fetchThermal = true,
    bool fetchElectrical = true,
    bool fetchHealth = true,
    bool fetchEnvironment = true,
    bool fetchLocation = true,
    bool fetchMotion = true,
    bool fetchActivity = true,
  }) async {
    Map<String, dynamic> finalMap = {};

    try {
      final arguments = {
        'fetchDeviceInfo': fetchDeviceInfo,
        'fetchBasic': fetchBasic,
        'fetchThermal': fetchThermal,
        'fetchElectrical': fetchElectrical,
        'fetchHealth': fetchHealth,
        'fetchEnvironment': fetchEnvironment,
        'fetchLocation': fetchLocation,
        'fetchMotion': fetchMotion,
      };

      final nativeResult = await _channel.invokeMethod(
        'getSensorData',
        arguments,
      );
      if (nativeResult != null) {
        finalMap.addAll(Map<String, dynamic>.from(nativeResult));
      }

      if (fetchActivity) {
        try {
          final activity = await FlutterActivityRecognition
              .instance
              .activityStream
              .first
              .timeout(
                const Duration(milliseconds: 500),
                onTimeout: () =>
                    Activity(ActivityType.UNKNOWN, ActivityConfidence.LOW),
              );

          finalMap['activityType'] = activity.type.toString().split('.').last;
          finalMap['activityConfidence'] = activity.confidence
              .toString()
              .split('.')
              .last;
        } catch (e) {
          finalMap['activityType'] = "UNKNOWN";
        }
      }
    } catch (e) {
      // Catch platform exceptions. Fails gracefully returning nulls if permissions are missing.
    }

    return DeviceContextData.fromMap(finalMap);
  }
}
