import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_context/device_context.dart';
import 'package:device_context/device_context_data.dart';

void main() {
  runApp(const DeviceContextExampleApp());
}

/// Main entry point for the Device Context Example Application.
class DeviceContextExampleApp extends StatefulWidget {
  const DeviceContextExampleApp({super.key});

  @override
  State<DeviceContextExampleApp> createState() =>
      _DeviceContextExampleAppState();
}

class _DeviceContextExampleAppState extends State<DeviceContextExampleApp> {
  DeviceContextData? _data;
  bool _isLoading = true;

  // --- Instant Fetch Category Flags ---
  bool _fetchDeviceInfo = true;
  bool _fetchBasic = true;
  bool _fetchThermal = true;
  bool _fetchElectrical = true;
  bool _fetchHealth = true;
  bool _fetchEnvironment = true;
  bool _fetchLocation = true;
  bool _fetchMotion = true;
  bool _fetchActivity = true;

  // --- Continuous Sampling Flags ---
  bool _enableContinuousSampling = false;
  final int _samplingWindowSeconds = 5; // 5-second sampling window
  final int _samplingHz = 20; // 20 updates per second

  @override
  void initState() {
    super.initState();
    _fetchHardwareData();
  }

  /// Fetches data using the new Configuration Object API.
  Future<void> _fetchHardwareData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await DeviceContext.getSensorData(
        // 1. Hardware Configuration
        hardware: HardwareConfig(
          deviceInfo: _fetchDeviceInfo,
          batteryStatus: _fetchBasic,
          instantElectricalDraw: _fetchElectrical,
          thermalState: _fetchThermal,
          batteryHealth: _fetchHealth,
        ),

        // 2. Instant Sensors Configuration
        instantSensors: InstantSensorsConfig(
          ambientLight: _fetchEnvironment,
          location: _fetchLocation,
          motionAndPosture: _fetchMotion,
          aiActivityPrediction: _fetchActivity,
        ),

        // 3. Continuous Sampling Configuration
        continuousSampling: _enableContinuousSampling
            ? ContinuousSamplingConfig(
                window: Duration(seconds: _samplingWindowSeconds),
                samplingRateHz: _samplingHz,
                averageElectricalDraw: true,
                averageMotionState: true,
                averageAmbientLight: true,
              )
            : null,
      );

      // --- Debug print of ALL fetched data ---
      debugPrint('\n--- 📱 DEVICE CONTEXT DATA FETCHED ---');
      if (_fetchDeviceInfo) {
        debugPrint(
          'Identity: ${data.identity?.manufacturer} ${data.identity?.brand} ${data.identity?.model} '
          '(Board: ${data.identity?.board}, HW: ${data.identity?.hardware}) '
          '[OS: ${data.identity?.osName} ${data.identity?.osVersion}] '
          'ID: ${data.identity?.deviceId}',
        );
      }
      if (_fetchBasic || _fetchElectrical || _fetchHealth) {
        debugPrint(
          'Battery (Basic): ${data.battery?.level}%, Status: ${data.battery?.status}, Plugged: ${data.battery?.pluggedStatus}',
        );
        debugPrint(
          'Battery (Electrical): ${data.battery?.currentNowMA} mA, ${data.battery?.voltage} mV (Mean Current: ${data.battery?.meanCurrentMA} mA)',
        );
        debugPrint(
          'Battery (Health): Code ${data.battery?.health}, Cycles: ${data.battery?.cycleCount}, Capacity: ${data.battery?.chargeCounterMAh} mAh',
        );
      }
      if (_fetchThermal) {
        debugPrint(
          'Thermal: Battery ${data.thermal?.batteryTemp}°C, CPU ${data.thermal?.cpuTemp}°C (Status: ${data.thermal?.thermalStatus})',
        );
      }
      if (_fetchEnvironment) {
        debugPrint(
          'Environment: ${data.environment?.lightLux} lux (Mean: ${data.environment?.meanLightLux} lux)',
        );
      }
      if (_fetchLocation) {
        debugPrint(
          'Location: Lat ${data.location?.latitude}, Lng ${data.location?.longitude}, Alt ${data.location?.altitude}m',
        );
      }
      if (_fetchMotion) {
        debugPrint(
          'Motion (Instant): Posture: ${data.motion?.posture}, State: ${data.motion?.motionState}',
        );
        debugPrint(
          'Motion (Proximity): ${data.motion?.proximityCm}cm, Covered: ${data.motion?.isCovered}',
        );
        debugPrint(
          'Motion (Raw Accel): [X: ${data.motion?.accelX?.toStringAsFixed(2)}, Y: ${data.motion?.accelY?.toStringAsFixed(2)}, Z: ${data.motion?.accelZ?.toStringAsFixed(2)}]',
        );
        debugPrint(
          'Motion (Mean): State: ${data.motion?.meanMotionState}, Accel: [X: ${data.motion?.meanAccelX?.toStringAsFixed(2)}, Y: ${data.motion?.meanAccelY?.toStringAsFixed(2)}, Z: ${data.motion?.meanAccelZ?.toStringAsFixed(2)}]',
        );
      }
      if (_fetchActivity) {
        debugPrint(
          'Activity (AI): ${data.activity?.activityType} (Confidence: ${data.activity?.activityConfidence})',
        );
      }
      debugPrint('--------------------------------------\n');
      // ----------------------------------------------

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch sensor data: $e')),
        );
      }
    }
  }

  // MARK: - Decoding Helpers

  String _getThermalStatusString(int? status) {
    switch (status) {
      case 0:
        return "Nominal (0)";
      case 1:
        return "Fair (1)";
      case 2:
        return "Serious (2)";
      case 3:
        return "Severe (3)";
      case 4:
        return "Critical (4)";
      default:
        return "Unknown";
    }
  }

  String _getChargeStatusString(int? status) {
    switch (status) {
      case 2:
        return "Charging";
      case 3:
        return "Discharging";
      case 4:
        return "Not Charging";
      case 5:
        return "Full";
      default:
        return "Unknown";
    }
  }

  String _getHealthString(int? health) {
    switch (health) {
      case 2:
        return "Good";
      case 3:
        return "Overheating";
      case 4:
        return "Dead";
      case 5:
        return "Over Voltage";
      case 7:
        return "Cold";
      default:
        return "Unknown";
    }
  }

  String _getPluggedString(int? plugged) {
    switch (plugged) {
      case 0:
        return "On Battery";
      case 1:
        return "AC Charger";
      case 2:
        return "USB Port";
      case 4:
        return "Wireless";
      default:
        return "Unknown";
    }
  }

  // MARK: - UI Builders

  Widget _buildDataRow(
    String icon,
    String label,
    String? value,
    bool isEnabled, {
    bool isMeanValue = false,
  }) {
    final textColor = isEnabled
        ? (isMeanValue ? Colors.cyanAccent : Colors.white)
        : Colors.white24;
    final displayValue = isEnabled ? (value ?? 'N/A') : 'Disabled';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isEnabled ? Colors.white70 : Colors.white24,
                fontStyle: isMeanValue ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    List<Widget> children,
    bool isEnabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              color: isEnabled ? Colors.blueGrey : Colors.white24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          color: const Color(0xFF2C2C2E),
          margin: const EdgeInsets.only(bottom: 24.0),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isEnabled ? Colors.transparent : Colors.white10,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Device Context Data'),
          backgroundColor: Colors.blueGrey[900],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Sampling hardware sensors..."),
                  ],
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- CONFIGURATION SECTION ---
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          "CONFIGURATION",
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Card(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        child: SwitchListTile(
                          title: const Text("Continuous Sampling Mode"),
                          subtitle: Text(
                            "Averages motion, light, and electrical data over $_samplingWindowSeconds seconds at ${_samplingHz}Hz.",
                          ),
                          value: _enableContinuousSampling,
                          activeThumbColor: Colors.cyanAccent,
                          onChanged: (val) {
                            setState(() => _enableContinuousSampling = val);
                            _fetchHardwareData();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: -4.0,
                        children: [
                          FilterChip(
                            label: const Text('Device Info'),
                            selected: _fetchDeviceInfo,
                            onSelected: (v) =>
                                setState(() => _fetchDeviceInfo = v),
                          ),
                          FilterChip(
                            label: const Text('Basic'),
                            selected: _fetchBasic,
                            onSelected: (v) => setState(() => _fetchBasic = v),
                          ),
                          FilterChip(
                            label: const Text('Thermal'),
                            selected: _fetchThermal,
                            onSelected: (v) =>
                                setState(() => _fetchThermal = v),
                          ),
                          FilterChip(
                            label: const Text('Electrical'),
                            selected: _fetchElectrical,
                            onSelected: (v) =>
                                setState(() => _fetchElectrical = v),
                          ),
                          FilterChip(
                            label: const Text('Health'),
                            selected: _fetchHealth,
                            onSelected: (v) => setState(() => _fetchHealth = v),
                          ),
                          FilterChip(
                            label: const Text('Environment'),
                            selected: _fetchEnvironment,
                            onSelected: (v) =>
                                setState(() => _fetchEnvironment = v),
                          ),
                          FilterChip(
                            label: const Text('Location'),
                            selected: _fetchLocation,
                            onSelected: (v) =>
                                setState(() => _fetchLocation = v),
                          ),
                          FilterChip(
                            label: const Text('Motion'),
                            selected: _fetchMotion,
                            onSelected: (v) => setState(() => _fetchMotion = v),
                          ),
                          FilterChip(
                            label: const Text('Activity (AI)'),
                            selected: _fetchActivity,
                            onSelected: (v) =>
                                setState(() => _fetchActivity = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- 0. DEVICE IDENTITY ---
                      _buildCategoryCard("DEVICE IDENTITY", [
                        _buildDataRow(
                          '🏢',
                          'Manufacturer',
                          _data?.identity?.manufacturer,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '🏷️',
                          'Brand',
                          _data?.identity?.brand,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '📱',
                          'Model',
                          _data?.identity?.model,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '🖥️',
                          'Board',
                          _data?.identity?.board,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '🔩',
                          'Hardware',
                          _data?.identity?.hardware,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '⚙️',
                          'OS Version',
                          _data?.identity?.osName != null
                              ? '${_data!.identity!.osName} ${_data!.identity!.osVersion}'
                              : null,
                          _fetchDeviceInfo,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          '🔑',
                          'Device ID',
                          _data?.identity?.deviceId,
                          _fetchDeviceInfo,
                        ),
                      ], _fetchDeviceInfo),

                      // --- 1. BATTERY (Merged Basic, Electrical, Health) ---
                      _buildCategoryCard(
                        "BATTERY & POWER",
                        [
                          _buildDataRow(
                            '🔋',
                            'Battery Level',
                            _data?.battery?.level != null
                                ? '${_data!.battery!.level}%'
                                : null,
                            _fetchBasic,
                          ),
                          _buildDataRow(
                            '🔄',
                            'Charge State',
                            _getChargeStatusString(_data?.battery?.status),
                            _fetchBasic,
                          ),
                          _buildDataRow(
                            '🔗',
                            'Power Source',
                            _getPluggedString(_data?.battery?.pluggedStatus),
                            _fetchBasic,
                          ),
                          const Divider(height: 24, color: Colors.white10),
                          _buildDataRow(
                            '⚡',
                            'Current (Instant)',
                            _data?.battery?.currentNowMA != null
                                ? '${_data!.battery!.currentNowMA} mA'
                                : null,
                            _fetchElectrical,
                          ),
                          _buildDataRow(
                            '📈',
                            'Current (Mean)',
                            _data?.battery?.meanCurrentMA != null
                                ? '${_data!.battery!.meanCurrentMA!.toStringAsFixed(1)} mA'
                                : null,
                            _enableContinuousSampling,
                            isMeanValue: true,
                          ),
                          _buildDataRow(
                            '🔌',
                            'Voltage',
                            _data?.battery?.voltage != null
                                ? '${_data!.battery!.voltage} mV'
                                : null,
                            _fetchElectrical,
                          ),
                          const Divider(height: 24, color: Colors.white10),
                          _buildDataRow(
                            '❤️',
                            'Battery Health',
                            _getHealthString(_data?.battery?.health),
                            _fetchHealth,
                          ),
                          _buildDataRow(
                            '♻️',
                            'Cycle Count',
                            _data?.battery?.cycleCount?.toString(),
                            _fetchHealth,
                          ),
                          _buildDataRow(
                            '📊',
                            'Charge Capacity',
                            _data?.battery?.chargeCounterMAh != null
                                ? '${_data!.battery!.chargeCounterMAh} mAh'
                                : null,
                            _fetchHealth,
                          ),
                        ],
                        _fetchBasic || _fetchElectrical || _fetchHealth,
                      ),

                      // --- 2. THERMAL ---
                      _buildCategoryCard("THERMAL", [
                        _buildDataRow(
                          '🌡️',
                          'Battery Temp',
                          _data?.thermal?.batteryTemp != null
                              ? '${_data!.thermal!.batteryTemp} °C'
                              : null,
                          _fetchThermal,
                        ),
                        _buildDataRow(
                          '💻',
                          'CPU Temp',
                          _data?.thermal?.cpuTemp != null
                              ? '${_data!.thermal!.cpuTemp} °C'
                              : null,
                          _fetchThermal,
                        ),
                        _buildDataRow(
                          '🔥',
                          'Thermal Status',
                          _getThermalStatusString(
                            _data?.thermal?.thermalStatus,
                          ),
                          _fetchThermal,
                        ),
                      ], _fetchThermal),

                      // --- 3. ENVIRONMENT & LOCATION ---
                      _buildCategoryCard("ENVIRONMENT & GPS", [
                        _buildDataRow(
                          '☀️',
                          'Light (Instant)',
                          _data?.environment?.lightLux != null
                              ? '${_data!.environment!.lightLux!.toInt()} lux'
                              : null,
                          _fetchEnvironment,
                        ),
                        _buildDataRow(
                          '🌤️',
                          'Light (Mean)',
                          _data?.environment?.meanLightLux != null
                              ? '${_data!.environment!.meanLightLux!.toStringAsFixed(1)} lux'
                              : null,
                          _enableContinuousSampling,
                          isMeanValue: true,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          '📍',
                          'Latitude',
                          _data?.location?.latitude?.toString(),
                          _fetchLocation,
                        ),
                        _buildDataRow(
                          '📍',
                          'Longitude',
                          _data?.location?.longitude?.toString(),
                          _fetchLocation,
                        ),
                        _buildDataRow(
                          '⛰️',
                          'Altitude',
                          _data?.location?.altitude != null
                              ? '${_data!.location!.altitude!.toStringAsFixed(1)} m'
                              : null,
                          _fetchLocation,
                        ),
                      ], _fetchEnvironment || _fetchLocation),

                      // --- 4. MOTION & ACTIVITY ---
                      _buildCategoryCard("MOTION & ACTIVITY", [
                        _buildDataRow(
                          '🧠',
                          'Activity (AI)',
                          _data?.activity?.activityType,
                          _fetchActivity,
                        ),
                        _buildDataRow(
                          '🎯',
                          'AI Confidence',
                          _data?.activity?.activityConfidence,
                          _fetchActivity,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          '📱',
                          'Posture',
                          _data?.motion?.posture,
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          '🏃‍♂️',
                          'Motion (Instant)',
                          _data?.motion?.motionState,
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          '📉',
                          'Motion (Mean)',
                          _data?.motion?.meanMotionState,
                          _enableContinuousSampling,
                          isMeanValue: true,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          '🙈',
                          'Proximity',
                          _data?.motion?.proximityCm != null
                              ? '${_data!.motion!.proximityCm} cm'
                              : null,
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          '👖',
                          'Covered / Pocket',
                          _data?.motion?.isCovered != null
                              ? (_data!.motion!.isCovered! ? 'Yes' : 'No')
                              : null,
                          _fetchMotion,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          'X',
                          'Accel X (Instant)',
                          _data?.motion?.accelX?.toStringAsFixed(2),
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          'Y',
                          'Accel Y (Instant)',
                          _data?.motion?.accelY?.toStringAsFixed(2),
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          'Z',
                          'Accel Z (Instant)',
                          _data?.motion?.accelZ?.toStringAsFixed(2),
                          _fetchMotion,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          'X',
                          'Accel X (Mean)',
                          _data?.motion?.meanAccelX?.toStringAsFixed(2),
                          _enableContinuousSampling,
                          isMeanValue: true,
                        ),
                        _buildDataRow(
                          'Y',
                          'Accel Y (Mean)',
                          _data?.motion?.meanAccelY?.toStringAsFixed(2),
                          _enableContinuousSampling,
                          isMeanValue: true,
                        ),
                        _buildDataRow(
                          'Z',
                          'Accel Z (Mean)',
                          _data?.motion?.meanAccelZ?.toStringAsFixed(2),
                          _enableContinuousSampling,
                          isMeanValue: true,
                        ),
                      ], _fetchMotion || _fetchActivity),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isLoading ? null : () => _fetchHardwareData(),
          icon: const Icon(Icons.refresh),
          label: const Text("Sample Data"),
          backgroundColor: Colors.cyan[700],
        ),
      ),
    );
  }
}
