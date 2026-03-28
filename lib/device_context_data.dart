/// Safely parses numbers from the platform channel (which sometimes mixes ints and doubles)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return null;
}

/// The root container for all hardware and environmental context data.
class DeviceContextData {
  final DeviceIdentity? identity;
  final BatteryData? battery;
  final ThermalData? thermal;
  final EnvironmentData? environment;
  final LocationData? location;
  final MotionData? motion;
  final ActivityData? activity;

  const DeviceContextData({
    this.identity,
    this.battery,
    this.thermal,
    this.environment,
    this.location,
    this.motion,
    this.activity,
  });

  factory DeviceContextData.fromMap(Map<String, dynamic> map) {
    return DeviceContextData(
      identity: DeviceIdentity.fromMap(map),
      battery: BatteryData.fromMap(map),
      thermal: ThermalData.fromMap(map),
      environment: EnvironmentData.fromMap(map),
      location: LocationData.fromMap(map),
      motion: MotionData.fromMap(map),
      activity: ActivityData.fromMap(map),
    );
  }
}

/// Static information about the device hardware and operating system.
class DeviceIdentity {
  final String? manufacturer;
  final String? model;
  final String? brand;
  final String? board;
  final String? hardware;
  final String? osName;
  final String? osVersion;

  /// A unique identifier for the device (Android ID or iOS IdentifierForVendor).
  final String? deviceId;

  const DeviceIdentity({
    this.manufacturer,
    this.model,
    this.brand,
    this.board,
    this.hardware,
    this.osName,
    this.osVersion,
    this.deviceId,
  });

  factory DeviceIdentity.fromMap(Map<String, dynamic> map) => DeviceIdentity(
    manufacturer: map['manufacturer'] as String?,
    model: map['model'] as String?,
    brand: map['brand'] as String?,
    board: map['board'] as String?,
    hardware: map['hardware'] as String?,
    osName: map['osName'] as String?,
    osVersion: map['osVersion'] as String?,
    deviceId: map['deviceId'] as String?,
  );
}

/// Comprehensive power, charging, electrical, and health metrics for the battery.
class BatteryData {
  // --- Basic State ---
  /// Current battery level as a percentage (0-100).
  final int? level;

  /// Native OS integer representing charging state (e.g., Charging, Discharging).
  final int? status;

  /// Native OS integer representing the power source (e.g., AC, USB, Wireless).
  final int? pluggedStatus;

  // --- Electrical Metrics ---
  /// Instantaneous battery current flow in milliAmps (mA).
  /// Negative usually implies discharging, positive implies charging.
  final int? currentNowMA;

  /// Instantaneous battery voltage in milliVolts (mV).
  final int? voltage;

  /// The average electrical current flow in milliAmps (mA) calculated over a continuous sampling window.
  final double? meanCurrentMA;

  // --- Health Metrics ---
  /// Native OS integer indicating overall battery health (e.g., Good, Overheating).
  final int? health;

  /// The number of full charge cycles the battery has undergone.
  final int? cycleCount;

  /// The estimated remaining battery capacity in milliAmp-hours (mAh).
  final int? chargeCounterMAh;

  const BatteryData({
    this.level,
    this.status,
    this.pluggedStatus,
    this.currentNowMA,
    this.voltage,
    this.meanCurrentMA,
    this.health,
    this.cycleCount,
    this.chargeCounterMAh,
  });

  factory BatteryData.fromMap(Map<String, dynamic> map) => BatteryData(
    level: map['batteryLevel'] as int?,
    status: map['status'] as int?,
    pluggedStatus: map['pluggedStatus'] as int?,
    currentNowMA: (map['currentNow_mA'] as num?)?.toInt(),
    voltage: (map['voltage'] as num?)?.toInt(),
    meanCurrentMA: _parseDouble(map['mean_current_mA']),
    health: map['health'] as int?,
    cycleCount: map['cycleCount'] as int?,
    chargeCounterMAh: map['chargeCounter_mAh'] as int?,
  );
}

/// Device temperature metrics.
class ThermalData {
  /// Battery temperature in Celsius.
  final double? batteryTemp;

  /// CPU temperature in Celsius (Hardware permitting).
  final double? cpuTemp;

  /// Native OS integer indicating thermal throttling state (e.g., Nominal, Severe).
  final int? thermalStatus;

  const ThermalData({this.batteryTemp, this.cpuTemp, this.thermalStatus});

  factory ThermalData.fromMap(Map<String, dynamic> map) => ThermalData(
    batteryTemp: _parseDouble(map['batteryTemp']),
    cpuTemp: _parseDouble(map['cpuTemp']),
    thermalStatus: map['thermalStatus'] as int?,
  );
}

/// Ambient environmental data.
class EnvironmentData {
  /// Instantaneous ambient light level measured in Lux.
  final double? lightLux;

  /// The average ambient light level (Lux) calculated over a continuous sampling window.
  final double? meanLightLux;

  const EnvironmentData({this.lightLux, this.meanLightLux});

  factory EnvironmentData.fromMap(Map<String, dynamic> map) => EnvironmentData(
    lightLux: _parseDouble(map['light_lux']),
    meanLightLux: _parseDouble(map['mean_light_lux']),
  );
}

/// Coarse geographic location data.
class LocationData {
  final double? latitude;
  final double? longitude;
  final double? altitude;

  const LocationData({this.latitude, this.longitude, this.altitude});

  factory LocationData.fromMap(Map<String, dynamic> map) => LocationData(
    latitude: _parseDouble(map['latitude']),
    longitude: _parseDouble(map['longitude']),
    altitude: _parseDouble(map['altitude']),
  );
}

/// Physical orientation and movement data.
class MotionData {
  /// The physical orientation of the device (e.g., Face Up, Portrait, Landscape).
  final String? posture;

  /// Instantaneous estimation of motion (e.g., "Moving" vs "Still").
  final String? motionState;

  /// Smoothed estimation of motion calculated over a continuous sampling window.
  final String? meanMotionState;

  /// Distance from the proximity sensor in centimeters.
  final double? proximityCm;

  /// True if the proximity sensor is fully covered (e.g., in a pocket or face down on a table).
  final bool? isCovered;

  /// Instantaneous raw X-axis acceleration.
  final double? accelX;

  /// Instantaneous raw Y-axis acceleration.
  final double? accelY;

  /// Instantaneous raw Z-axis acceleration.
  final double? accelZ;

  /// Mean X-axis acceleration over a continuous sampling window.
  final double? meanAccelX;

  /// Mean Y-axis acceleration over a continuous sampling window.
  final double? meanAccelY;

  /// Mean Z-axis acceleration over a continuous sampling window.
  final double? meanAccelZ;

  const MotionData({
    this.posture,
    this.motionState,
    this.meanMotionState,
    this.proximityCm,
    this.isCovered,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.meanAccelX,
    this.meanAccelY,
    this.meanAccelZ,
  });

  factory MotionData.fromMap(Map<String, dynamic> map) => MotionData(
    posture: map['posture'] as String?,
    motionState: map['motionState'] as String?,
    meanMotionState: map['mean_motionState'] as String?,
    proximityCm: _parseDouble(map['proximity_cm']),
    isCovered: map['isCovered'] as bool?,
    accelX: _parseDouble(map['accelX']),
    accelY: _parseDouble(map['accelY']),
    accelZ: _parseDouble(map['accelZ']),
    meanAccelX: _parseDouble(map['mean_accelX']),
    meanAccelY: _parseDouble(map['mean_accelY']),
    meanAccelZ: _parseDouble(map['mean_accelZ']),
  );
}

/// AI-powered activity predictions.
class ActivityData {
  /// The predicted user activity (e.g., WALKING, IN_VEHICLE, STILL).
  final String? activityType;

  /// The confidence level of the prediction (e.g., HIGH, MEDIUM, LOW).
  final String? activityConfidence;

  const ActivityData({this.activityType, this.activityConfidence});

  factory ActivityData.fromMap(Map<String, dynamic> map) => ActivityData(
    activityType: map['activityType'] as String?,
    activityConfidence: map['activityConfidence'] as String?,
  );
}
