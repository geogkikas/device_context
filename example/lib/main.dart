import 'package:device_context/device_context_data.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:device_context/device_context.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DeviceContextData? _data;
  bool _isLoading = true;

  // --- Category Flags ---
  bool _fetchDeviceInfo = true;
  bool _fetchBasic = true;
  bool _fetchThermal = true;
  bool _fetchElectrical = true;
  bool _fetchHealth = true;
  bool _fetchEnvironment = true;
  bool _fetchLocation = true;
  bool _fetchMotion = true;
  bool _fetchActivity = true;

  @override
  void initState() {
    super.initState();
    _fetchHardwareData();
  }

  Future<void> _fetchHardwareData() async {
    try {
      final data = await DeviceContext.getSensorData(
        fetchDeviceInfo: _fetchDeviceInfo,
        fetchBasic: _fetchBasic,
        fetchThermal: _fetchThermal,
        fetchElectrical: _fetchElectrical,
        fetchHealth: _fetchHealth,
        fetchEnvironment: _fetchEnvironment,
        fetchLocation: _fetchLocation,
        fetchMotion: _fetchMotion,
        fetchActivity: _fetchActivity,
      );

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Decoding Helpers ---
  String? _getThermalStatusString(int? status) {
    if (status == null) return null;
    switch (status) {
      case 0:
        return "Normal (0)";
      case 1:
        return "Light (1)";
      case 2:
        return "Moderate (2)";
      case 3:
        return "Severe (3)";
      case 4:
        return "Critical (4)";
      default:
        return "Unknown";
    }
  }

  String? _getChargeStatusString(int? status) {
    if (status == null) return null;
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

  String? _getHealthString(int? health) {
    if (health == null) return null;
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

  String? _getPluggedString(int? plugged) {
    if (plugged == null) return null;
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

  // --- UI Builders ---
  Widget _buildDataRow(
    String icon,
    String label,
    String? value,
    bool isEnabled,
  ) {
    final color = isEnabled ? Colors.white : Colors.white24;
    final displayValue = isEnabled ? (value ?? 'N/A') : 'Disabled';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isEnabled ? Colors.white70 : Colors.white24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
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
          title: const Text('Hardware Context'),
          backgroundColor: Colors.blueGrey[900],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
                          "DATA CATEGORIES",
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          FilterChip(
                            label: const Text('Device Info'),
                            selected: _fetchDeviceInfo,
                            onSelected: (v) {
                              setState(() => _fetchDeviceInfo = v);
                              _fetchHardwareData();
                            },
                          ),
                          FilterChip(
                            label: const Text('Basic'),
                            selected: _fetchBasic,
                            onSelected: (v) {
                              setState(() => _fetchBasic = v);
                              _fetchHardwareData();
                            },
                          ),
                          FilterChip(
                            label: const Text('Thermal'),
                            selected: _fetchThermal,
                            onSelected: (v) {
                              setState(() => _fetchThermal = v);
                              _fetchHardwareData();
                            },
                          ),
                          FilterChip(
                            label: const Text('Electrical'),
                            selected: _fetchElectrical,
                            onSelected: (v) {
                              setState(() => _fetchElectrical = v);
                              _fetchHardwareData();
                            },
                          ),
                          FilterChip(
                            label: const Text('Health'),
                            selected: _fetchHealth,
                            onSelected: (v) {
                              setState(() => _fetchHealth = v);
                              _fetchHardwareData();
                            },
                          ),
                          FilterChip(
                            label: const Text('Environment'),
                            selected: _fetchEnvironment,
                            onSelected: (v) {
                              setState(() => _fetchEnvironment = v);
                              _fetchHardwareData();
                            },
                          ),
                          FilterChip(
                            label: const Text('Location'),
                            selected: _fetchLocation,
                            onSelected: (v) {
                              setState(() => _fetchLocation = v);
                              _fetchHardwareData();
                            },
                          ),
                          FilterChip(
                            label: const Text('Motion'),
                            selected: _fetchMotion,
                            onSelected: (v) {
                              setState(() => _fetchMotion = v);
                              _fetchHardwareData();
                            },
                          ),
                          FilterChip(
                            label: const Text('Activity (AI)'),
                            selected: _fetchActivity,
                            onSelected: (v) {
                              setState(() => _fetchActivity = v);
                              _fetchHardwareData();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- 0. DEVICE INFO ---
                      _buildCategoryCard("DEVICE INFO", [
                        _buildDataRow(
                          '🏢',
                          'Manufacturer',
                          _data?.deviceInfo?.manufacturer,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '🏷️',
                          'Brand',
                          _data?.deviceInfo?.brand,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '📱',
                          'Model',
                          _data?.deviceInfo?.model,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '🖥️',
                          'Board',
                          _data?.deviceInfo?.board,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '🔩',
                          'Hardware',
                          _data?.deviceInfo?.hardware,
                          _fetchDeviceInfo,
                        ),
                        _buildDataRow(
                          '⚙️',
                          'OS Version',
                          _data?.deviceInfo?.osName != null
                              ? '${_data!.deviceInfo!.osName} ${_data!.deviceInfo!.osVersion}'
                              : null,
                          _fetchDeviceInfo,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          '🔑',
                          'Device ID',
                          _data?.deviceInfo?.deviceId,
                          _fetchDeviceInfo,
                        ),
                      ], _fetchDeviceInfo),

                      // --- 1. BASIC & ELECTRICAL ---
                      _buildCategoryCard("POWER STATUS", [
                        _buildDataRow(
                          '🔋',
                          'Battery Level',
                          _data?.basic?.batteryLevel != null
                              ? '${_data!.basic!.batteryLevel}%'
                              : null,
                          _fetchBasic,
                        ),
                        _buildDataRow(
                          '🔄',
                          'Charge State',
                          _getChargeStatusString(_data?.basic?.status),
                          _fetchBasic,
                        ),
                        _buildDataRow(
                          '🔗',
                          'Power Source',
                          _getPluggedString(_data?.basic?.pluggedStatus),
                          _fetchBasic,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          '⚡',
                          'Current (Now)',
                          _data?.electrical?.currentNowMA != null
                              ? '${_data!.electrical!.currentNowMA} mA'
                              : null,
                          _fetchElectrical,
                        ),
                        _buildDataRow(
                          '🔌',
                          'Voltage',
                          _data?.electrical?.voltage != null
                              ? '${_data!.electrical!.voltage} mV'
                              : null,
                          _fetchElectrical,
                        ),
                      ], _fetchBasic || _fetchElectrical),

                      // --- 2. THERMAL ---
                      _buildCategoryCard("THERMAL DATA", [
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

                      // --- 3. HEALTH ---
                      _buildCategoryCard("BATTERY HEALTH", [
                        _buildDataRow(
                          '❤️',
                          'Battery Health',
                          _getHealthString(_data?.health?.health),
                          _fetchHealth,
                        ),
                        _buildDataRow(
                          '📊',
                          'Charge Capacity',
                          _data?.health?.chargeCounterMAh != null
                              ? '${_data!.health!.chargeCounterMAh} mAh'
                              : null,
                          _fetchHealth,
                        ),
                        _buildDataRow(
                          '♻️',
                          'Cycle Count',
                          _data?.health?.cycleCount != null
                              ? '${_data!.health!.cycleCount}'
                              : null,
                          _fetchHealth,
                        ),
                      ], _fetchHealth),

                      // --- 4. ENVIRONMENT & LOCATION ---
                      _buildCategoryCard("ENVIRONMENT & GPS", [
                        _buildDataRow(
                          '☀️',
                          'Ambient Light',
                          _data?.environment?.lightLux != null
                              ? '${_data!.environment!.lightLux!.toInt()} lux'
                              : null,
                          _fetchEnvironment,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          '📍',
                          'Latitude',
                          _data?.location?.latitude != null
                              ? '${_data!.location!.latitude}'
                              : null,
                          _fetchLocation,
                        ),
                        _buildDataRow(
                          '📍',
                          'Longitude',
                          _data?.location?.longitude != null
                              ? '${_data!.location!.longitude}'
                              : null,
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

                      // --- 5. MOTION & ACTIVITY ---
                      _buildCategoryCard("MOTION & ACTIVITY", [
                        _buildDataRow(
                          '📱',
                          'Posture',
                          _data?.motion?.posture != null
                              ? '${_data!.motion!.posture}'
                              : null,
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          '🏃‍♂️',
                          'Motion (Manual)',
                          _data?.motion?.motionState != null
                              ? '${_data!.motion!.motionState}'
                              : null,
                          _fetchMotion,
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        _buildDataRow(
                          '🧠',
                          'Activity (AI)',
                          _data?.activity?.activityType != null
                              ? '${_data!.activity!.activityType}'
                              : null,
                          _fetchActivity,
                        ),
                        _buildDataRow(
                          '🎯',
                          'AI Confidence',
                          _data?.activity?.activityConfidence != null
                              ? '${_data!.activity!.activityConfidence}'
                              : null,
                          _fetchActivity,
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
                          'In Pocket',
                          _data?.motion?.isCovered != null
                              ? (_data!.motion!.isCovered! ? 'Yes' : 'No')
                              : null,
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          'X',
                          'Accel X',
                          _data?.motion?.accelX?.toStringAsFixed(2),
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          'Y',
                          'Accel Y',
                          _data?.motion?.accelY?.toStringAsFixed(2),
                          _fetchMotion,
                        ),
                        _buildDataRow(
                          'Z',
                          'Accel Z',
                          _data?.motion?.accelZ?.toStringAsFixed(2),
                          _fetchMotion,
                        ),
                      ], _fetchMotion || _fetchActivity),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _fetchHardwareData(),
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh"),
        ),
      ),
    );
  }
}
