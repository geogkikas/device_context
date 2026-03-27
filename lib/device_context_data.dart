/// Safely parses numbers from the platform channel (which sometimes mixes ints and doubles)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return null;
}

class DeviceContextData {
  final DeviceInfoData? deviceInfo;
  final BasicData? basic;
  final ThermalData? thermal;
  final ElectricalData? electrical;
  final HealthData? health;
  final EnvironmentData? environment;
  final LocationData? location;
  final MotionData? motion;
  final ActivityData? activity;

  DeviceContextData({
    this.deviceInfo,
    this.basic,
    this.thermal,
    this.electrical,
    this.health,
    this.environment,
    this.location,
    this.motion,
    this.activity,
  });

  factory DeviceContextData.fromMap(Map<String, dynamic> map) {
    return DeviceContextData(
      deviceInfo: DeviceInfoData.fromMap(map),
      basic: BasicData.fromMap(map),
      thermal: ThermalData.fromMap(map),
      electrical: ElectricalData.fromMap(map),
      health: HealthData.fromMap(map),
      environment: EnvironmentData.fromMap(map),
      location: LocationData.fromMap(map),
      motion: MotionData.fromMap(map),
      activity: ActivityData.fromMap(map),
    );
  }
}

class DeviceInfoData {
  final String? manufacturer;
  final String? model;
  final String? brand;
  final String? board;
  final String? hardware;
  final String? osName;
  final String? osVersion;
  final String? deviceId;

  DeviceInfoData({
    this.manufacturer,
    this.model,
    this.brand,
    this.board,
    this.hardware,
    this.osName,
    this.osVersion,
    this.deviceId,
  });

  factory DeviceInfoData.fromMap(Map<String, dynamic> map) => DeviceInfoData(
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

class BasicData {
  final int? batteryLevel;
  final int? status;
  final int? pluggedStatus;

  BasicData({this.batteryLevel, this.status, this.pluggedStatus});

  factory BasicData.fromMap(Map<String, dynamic> map) => BasicData(
    batteryLevel: map['batteryLevel'] as int?,
    status: map['status'] as int?,
    pluggedStatus: map['pluggedStatus'] as int?,
  );
}

class ThermalData {
  final double? batteryTemp;
  final double? cpuTemp;
  final int? thermalStatus;

  ThermalData({this.batteryTemp, this.cpuTemp, this.thermalStatus});

  factory ThermalData.fromMap(Map<String, dynamic> map) => ThermalData(
    batteryTemp: _parseDouble(map['batteryTemp']),
    cpuTemp: _parseDouble(map['cpuTemp']),
    thermalStatus: map['thermalStatus'] as int?,
  );
}

class ElectricalData {
  final int? currentNowMA;
  final int? voltage;

  ElectricalData({this.currentNowMA, this.voltage});

  factory ElectricalData.fromMap(Map<String, dynamic> map) => ElectricalData(
    currentNowMA: (map['currentNow_mA'] as num?)?.toInt(),
    voltage: (map['voltage'] as num?)?.toInt(),
  );
}

class HealthData {
  final int? health;
  final int? cycleCount;
  final int? chargeCounterMAh;

  HealthData({this.health, this.cycleCount, this.chargeCounterMAh});

  factory HealthData.fromMap(Map<String, dynamic> map) => HealthData(
    health: map['health'] as int?,
    cycleCount: map['cycleCount'] as int?,
    chargeCounterMAh: map['chargeCounter_mAh'] as int?,
  );
}

class EnvironmentData {
  final double? lightLux;

  EnvironmentData({this.lightLux});

  factory EnvironmentData.fromMap(Map<String, dynamic> map) =>
      EnvironmentData(lightLux: _parseDouble(map['light_lux']));
}

class LocationData {
  final double? latitude;
  final double? longitude;
  final double? altitude;

  LocationData({this.latitude, this.longitude, this.altitude});

  factory LocationData.fromMap(Map<String, dynamic> map) => LocationData(
    latitude: _parseDouble(map['latitude']),
    longitude: _parseDouble(map['longitude']),
    altitude: _parseDouble(map['altitude']),
  );
}

class MotionData {
  final String? posture;
  final String? motionState;
  final double? proximityCm;
  final bool? isCovered;
  final double? accelX;
  final double? accelY;
  final double? accelZ;

  MotionData({
    this.posture,
    this.motionState,
    this.proximityCm,
    this.isCovered,
    this.accelX,
    this.accelY,
    this.accelZ,
  });

  factory MotionData.fromMap(Map<String, dynamic> map) => MotionData(
    posture: map['posture'] as String?,
    motionState: map['motionState'] as String?,
    proximityCm: _parseDouble(map['proximity_cm']),
    isCovered: map['isCovered'] as bool?,
    accelX: _parseDouble(map['accelX']),
    accelY: _parseDouble(map['accelY']),
    accelZ: _parseDouble(map['accelZ']),
  );
}

class ActivityData {
  final String? activityType;
  final String? activityConfidence;

  ActivityData({this.activityType, this.activityConfidence});

  factory ActivityData.fromMap(Map<String, dynamic> map) => ActivityData(
    activityType: map['activityType'] as String?,
    activityConfidence: map['activityConfidence'] as String?,
  );
}
