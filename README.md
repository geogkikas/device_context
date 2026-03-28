# device_context 📱

A comprehensive Flutter plugin for extracting deep device context, hardware diagnostics, environmental data, and user activity.

Instead of relying on half a dozen different packages, device_context provides a single, unified API to grab a complete snapshot of the user's physical and hardware state. It handles native permission requests automatically, fails gracefully, and features a powerful Continuous Sampling Engine to average out noisy sensor data over time.




## 🚀 Features

* **Granular Control:** Fetch exactly what you need using strictly typed configuration objects (`HardwareConfig`, `InstantSensorsConfig`).

* **Continuous Sampling:** Accurately measure true battery drain, ambient light, and motion by averaging sensor data over a custom time window (e.g., 5 seconds) natively.

* **Dual Activity Tracking:** Combines zero-latency native hardware heuristics (Accelerometer math) with high-level OS AI (Activity Recognition).

* **Permission Agnostic (Bring Your Own UX):** The library focuses purely on data extraction. It will never force a system popup on your users. Silently returns `null` for restricted sensors.




## 📦 Installation

Since this package is hosted on GitHub, you can add it directly to your app's `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  device_context:
    git:
      url: https://github.com/geogkikas/device_context.git
      ref: main
```




## 🛠️ Native Setup (Required)

Because this plugin accesses deep system data, you must configure your native Android and iOS files.
**You only need to add the permissions for the categories you intend to fetch.**

### 🤖 Android Setup (`android/app/src/main/AndroidManifest.xml`)

Add the following inside your `<manifest>` tag, depending on what categories you set to true:

#### 1. Activity & Motion (`fetchActivity = true`)
```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="com.google.android.gms.permission.ACTIVITY_RECOGNITION" />

<application>
<service
    android:name="com.pravera.flutter_activity_recognition.service.ActivityRecognitionIntentService"
    android:permission="android.permission.BIND_JOB_SERVICE"
    android:exported="false" />
</application>
```

#### 2. Location Tracking (`fetchLocation = true`)

* _If you only fetch location while the app is open:_

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

* _If you intend to fetch location in the background (e.g., via a background isolate):_
```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```


>**⚠️ Background Location Notice:** If you intend to call `DeviceContext.getSensorData(fetchLocation: true)` from inside a background isolate, ensure your host app includes `foregroundServiceType="location"` (Android) and the `location` Background Mode (iOS). **You must also handle the OS permission requests (`permission_handler`) in your host app's UI before the background task runs.**
---
> **Note:** Android requires `compileSdkVersion 34` in `android/app/build.gradle` for full compatibility.



### 🍎 iOS Setup (`ios/Runner/Info.plist`)

Add the following keys to your `Info.plist`, depending on what categories you set to true:


#### 1. Activity & Motion (`fetchActivity = true` or `fetchMotion = true`)
```xml
<key>NSMotionUsageDescription</key>
<string>We need motion data to detect if you are walking, driving, or holding the device.</string>
```


#### 2. Location Tracking (`fetchLocation = true`)
* _If you only fetch location while the app is open:_

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide environmental context.</string>
```

* _If you intend to fetch location in the background (e.g., via a background isolate):_

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need location access in the background for continuous tracking.</string>
```

> **⚠️ App Store Note for Background Location:** If you use the "Always" permission to fetch location in the background, Apple requires you to explicitly justify this core functionality during app review.




## 💻 Usage & Quick Start

Call `DeviceContext.getSensorData()` using the declarative configuration objects. This eliminates boolean blindness and allows your IDE to provide full autocomplete.

```dart
import 'package:device_context/device_context.dart';
import 'package:permission_handler/permission_handler.dart'; // Handled by your app

void fetchAndProcessContext() async {
  // 1. Request permissions in your app's UI however you like
  await Permission.locationWhenInUse.request();
  await Permission.activityRecognition.request();

  // 2. Fetch data using structured configurations
  final data = await DeviceContext.getSensorData(
    hardware: const HardwareConfig(
      deviceInfo: true,
      batteryStatus: true,
      instantElectricalDraw: true,
      thermalState: true,
      batteryHealth: true,
    ),
    instantSensors: const InstantSensorsConfig(
      ambientLight: true,
      location: true,
      motionAndPosture: true,
      aiActivityPrediction: true,
    ),
    // Optional: Average out noisy data over 5 seconds natively
    continuousSampling: const ContinuousSamplingConfig(
      window: Duration(seconds: 5),
      averageElectricalDraw: true,
      averageMotionState: true,
    ),
  );

  // 3. Access data through clean, merged categories
  print("Stable ID:    ${data.identity?.deviceId}"); 
  print("Battery:      ${data.battery?.level}%");
  print("Mean Current: ${data.battery?.meanCurrentMA} mA");
  print("Location:     ${data.location?.latitude}, ${data.location?.longitude}");
  print("User State:   ${data.activity?.activityType}"); 
}
```




## 🗂️ Data Categories & Keys Reference

Every property is nullable. If a platform is marked with `❌`, the property will always return `null` on that OS. If marked with `✅`, it returns data provided the hardware supports it and permissions are granted.

### 1. `data.identity` (Hardware Identity)
| Key             | 	Type   | 	Description                                     | 	Android	 | iOS |
|:----------------|:--------|:-------------------------------------------------|:----------|:----|
| `manufacturer`	 | String  | 	Device maker (e.g., "Apple", "Samsung").        | 	✅	       | ✅   |
| `model`	        | String	 | Hardware model (e.g., "iPhone14,5", "RMX3890").	 | ✅         | 	✅  |
| `osName`	       | String	 | "Android" or "iOS".	                             | ✅	        | ✅   |
| `osVersion`	    | String	 | OS Version (e.g., "14", "17.4.1").	              | ✅	        | ✅   |
| `deviceId`	     | String  | 	Stable ID: Survives uninstalls.	                | ✅         | ✅   |


### 2. `data.battery` (Power, Electrical & Health)
| Key                | 	Type   | 	Description                                                         | 	Android	 | iOS |
|:-------------------|:--------|:---------------------------------------------------------------------|:----------|:----|
| `level`	           | int     | 	Battery percentage (0-100).	                                        | ✅	        | ✅   |           |     |
| `status`           | 	int    | 	OS Charge State: 2 (Charging), 3 (Discharging), 4 (Not), 5 (Full).	 | ✅         | 	✅  |
| `pluggedStatus`	   | int     | 	Power source: 0 (Battery), 1 (AC), 2 (USB), 4 (Wireless).	          | ✅	        | ❌   |
| `currentNowMA`     | 	int    | 	Instant current draw in mA. Negative = discharging.	                | ✅	        | ❌   |
| `meanCurrentMA`	   | double	 | Average mA draw over the ContinuousSamplingConfig window.	           | ✅         | 	❌  |
| `voltage`	         | int     | 	Current battery voltage in mV.	                                     | ✅	        | ❌   |
| `health`           | 	int    | 	OS Health rating: 2 (Good), 3 (Overheating), 4 (Dead).	             | ✅	        | ❌   |
| `cycleCount`       | 	int	   | Total battery charge cycles (Android 14+ only).	                     | ✅	        | ❌   |
| `chargeCounterMAh` | 	int	   | Maximum current charge capacity in mAh.	                             | ✅	        | ❌   |


### 3. `data.thermal` (Temperature)
| Key             | Type   | Description                                        | Android | iOS |
|:----------------|:-------|:---------------------------------------------------|:--------|:----|
| `batteryTemp`   | double | Battery temperature in Celsius.                    | ✅       | ❌   |
| `cpuTemp`       | double | CPU System temperature in Celsius.                 | ✅       | ❌   |
| `thermalStatus` | int    | OS Throttling state (0 to 4). See breakdown below. | ✅       | ✅   |

**Thermal Status Breakdown:**
* **`0` (Nominal):** Device is at a normal operating temperature. No throttling.
* **`1` (Fair):** Device is slightly warm. No active throttling yet, but the OS is monitoring.
* **`2` (Serious):** Device is hot. The OS may begin minor performance throttling to cool down.
* **`3` (Severe):** Device is very hot. Noticeable performance throttling is actively occurring.
* **`4` (Critical):** Dangerously hot. Major features (like flash or heavy processing) are disabled, and thermal shutdown is imminent.


### 4. `data.environment` & `data.location`
| Key            | 	Type   | 	Description                                            | 	Android	 | iOS |
|:---------------|:--------|:--------------------------------------------------------|:----------|:----|
| `lightLux`	    | double  | 	Instant ambient light sensor reading in Lux.           | 	✅	       | ❌   |
| `meanLightLux` | 	double | 	Average Lux over the ContinuousSamplingConfig window.	 | ✅         | 	❌  |
| `latitude`	    | double	 | Current GPS latitude.                                   | 	✅	       | ✅   |
| `longitude`	   | double	 | Current GPS longitude.	                                 | ✅	        | ✅   |
| `altitude`	    | double  | 	Current altitude in meters.                            | 	✅        | 	✅  |


### 5. `data.motion` (Hardware Physical State)
* _Calculated instantly or averaged natively via the accelerometer and proximity sensors._

| Key                  | 	Type  | 	Description                                                     | 	Android	 | iOS |
|:---------------------|:-------|:-----------------------------------------------------------------|:----------|:----|
| `activityType`       | String | AI prediction: "WALKING", "IN_VEHICLE", "STILL", "RUNNING", etc. | ✅	        | ✅	  |
| `activityConfidence` | String | Certainty level: "HIGH", "MEDIUM", "LOW".                        | ✅	        | ✅	  |




#### Implementation Notes for Developers:

* **iOS Limitations:** Apple considers Battery Temperature, Voltage, and Cycle Count to be private user data and does not provide public APIs for them. These fields will consistently return `null` on iOS.

* **Android `cpuTemp`:** This relies on reading system thermal zones. It may return `null` on some heavily locked-down Android distributions or specific kernel configurations.

* **Permissions:** If a platform supports a feature (✅) but the user denies the required permission (Location, Activity, etc.), that specific field will return `null`.




## 🏃‍♂️ Understanding `motionState` vs `activityType`

Why does this library offer two ways to track movement?

1. `motionState` **(Hardware Heuristic):** This relies on raw G-force math directly from the accelerometer. It has zero latency. If you bump a phone sitting on a desk, `motionState` will instantly report `"Moving"`. Use `ContinuousSamplingConfig` to smooth this out into `meanMotionState` to ignore brief bumps.

2. `activityType` **(OS AI):** This uses machine learning over several seconds to guess the user's overall behavior. If you bump a phone on a desk, the AI will still report `"STILL"` because the broader context hasn't changed.

By fetching both, developers can cross-reference data. For example, if `motionState == Moving` but `activityType == STILL`, the user is likely sitting at a desk but actively handling their phone.