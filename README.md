# device_context 📱

A comprehensive Flutter plugin for extracting deep device context, hardware diagnostics, environmental data, and user activity.

Instead of relying on half a dozen different packages, `device_context` provides a single, unified API to grab a complete snapshot of the user's physical and hardware state. It handles native permission requests automatically and fails gracefully, ensuring your app's background tasks remain stable.


___

## 🚀 Features

* **Granular Control:** Fetch only the data you need using category flags (e.g., `fetchThermal`, `fetchLocation`).

* **Dual Activity Tracking:** Combines zero-latency native hardware heuristics (Accelerometer math) with high-level OS AI (Activity Recognition).

* **Permission Agnostic (Bring Your Own UX):** The library focuses purely on data extraction. It will never force a system popup on your users. If you haven't requested permissions in your main app, it safely and silently returns `null` for restricted sensors.

___

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

___

## 🛠️ Native Setup (Required)

Because this plugin accesses deep system data, you must configure your native Android and iOS files. **You only need to add the permissions for the categories you intend to fetch.**

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

_If you only fetch location while the app is open:_

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

_If you intend to fetch location in the background (e.g., via a background isolate):_
```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```


> **⚠️ Background Location Notice:** If you intend to call `DeviceContext.getSensorData(fetchLocation: true)` from inside a background isolate, ensure your host app includes `foregroundServiceType="location"` (Android) and the `location` Background Mode (iOS). **You must also handle the OS permission requests (`permission_handler`) in your host app's UI before the background task runs.**

___
> **Note:** Android requires `compileSdkVersion 34` in `android/app/build.gradle` for full compatibility.
___


## 🍎 iOS Setup (`ios/Runner/Info.plist`)

Add the following keys to your `Info.plist`, depending on what categories you set to true:


#### 1. Activity & Motion (`fetchActivity = true` or `fetchMotion = true`)
```xml
<key>NSMotionUsageDescription</key>
<string>We need motion data to detect if you are walking, driving, or holding the device.</string>
```


#### 2. Location Tracking (`fetchLocation = true`)
_If you only fetch location while the app is open:_

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide environmental context.</string>
```

_If you intend to fetch location in the background (e.g., via a background isolate):_

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need location access in the background for continuous tracking.</string>
```

> **⚠️ App Store Note for Background Location:** If you use the "Always" permission to fetch location in the background, Apple requires you to explicitly justify this core functionality during app review.
___



## 💻 Usage & Quick Start

Call `DeviceContext.getSensorData()` to retrieve a strongly-typed `DeviceContextData` object. This structure eliminates the need for manual type casting or memorizing string keys—your IDE will provide full autocomplete for every category and field.

```dart
import 'package:device_context/device_context.dart';
import 'package:permission_handler/permission_handler.dart'; // Handled by the host app

void fetchAndProcessContext() async {
  // 1. Request permissions in your app's UI however you like
  await Permission.locationWhenInUse.request();
  await Permission.activityRecognition.request();

  // 2. Fetch data (100% safe to run in foreground or background)
  DeviceContextData data = await DeviceContext.getSensorData(
    fetchDeviceInfo: true,
    fetchBasic: true,
    fetchThermal: true,
    fetchElectrical: true,
    fetchLocation: true,
    fetchMotion: true,
    fetchActivity: true,
  );

  // 3. Access data through structured, null-safe categories
  print("Stable ID:    ${data.deviceInfo?.deviceId}"); 
  print("Battery:      ${data.basic?.batteryLevel}%");
  print("Location:     ${data.location?.latitude}, ${data.location?.longitude}");
  print("User State:   ${data.activity?.activityType}"); 
}
```


___

## 🗂️ Data Categories & Keys Reference

Every property is nullable. If a platform is marked with `❌`, the property will always return `null` on that OS. If marked with `✅`, it returns data provided the sensor exists and permissions are granted.

### 1. fetchDeviceInfo (Hardware Identity)

| Key             | 	Type   | 	Description                                     | 	Android	 | iOS |
|:----------------|:--------|:-------------------------------------------------|:----------|:----|
| `manufacturer`	 | String  | 	Device maker (e.g., "Apple", "Samsung").        | 	✅	       | ✅   |
| `model`	        | String	 | Hardware model (e.g., "iPhone14,5", "RMX3890").	 | ✅         | 	✅  |
| `osName`	       | String	 | "Android" or "iOS".	                             | ✅	        | ✅   |
| `osVersion`	    | String	 | OS Version (e.g., "14", "17.4.1").	              | ✅	        | ✅   |
| `deviceId`	     | String  | 	Stable ID: Survives uninstalls.	                | ✅         | ✅   |

### 2. fetchBasic (Power & Status)
| Key             | 	Type | 	Description                                                                | 	Android	 | iOS |
|:----------------|:------|:----------------------------------------------------------------------------|:----------|:----|
| `batteryLevel`  | 	int	 | Battery percentage (0-100).                                                 | ✅	        | ✅   |
| `status`        | 	int	 | OS Charge State: 2 (Charging), 3 (Discharging), 4 (Not Charging), 5 (Full). | ✅	        | ✅   |
| `pluggedStatus` | 	int	 | Power source: 0 (Battery), 1 (AC), 2 (USB), 4 (Wireless).                   | ✅	        | ❌   |

### 3. fetchThermal (Temperature)
| Key             | 	Type   | 	Description                                       | 	Android	 | iOS |
|:----------------|:--------|:---------------------------------------------------|:----------|:----|
| `batteryTemp`   | 	double | 	Battery temperature in Celsius.                   | ✅	        | ❌   |
| `cpuTemp`       | 	double | 	CPU System temperature in Celsius (Android only). | ✅	        | ❌   |
| `thermalStatus` | 	int	   | OS Throttling state: 0 (Normal) -> 4 (Critical).   | ✅	        | ✅   |

### 4. fetchElectrical (Power Draw)

| Key             | 	Type | 	Description                                                         | 	Android	 | iOS |
|:----------------|:------|:---------------------------------------------------------------------|:----------|:----|
| `currentNowMA`	 | int	  | Instantaneous current draw in milliamps. Negative means discharging. | ✅	        | ❌   |
| `voltage`       | 	int	 | Current battery voltage in millivolts.                               | ✅	        | ❌   |


### 5. fetchHealth (Battery Degradation)

| Key                | 	Type | 	Description                                                 | 	Android	 | iOS |
|:-------------------|:------|:-------------------------------------------------------------|:----------|:----|
| `health`           | 	int  | 	OS Health rating: 2 (Good), 3 (Overheating), 4 (Dead), etc. | ✅	        | ❌   |
| `cycleCount`       | 	int	 | Total battery charge cycles (Android 14+ only).              | ✅	        | ❌   |
| `chargeCounterMAh` | 	int	 | Maximum current charge capacity in mAh.                      | ✅	        | ❌   |


### 6. fetchEnvironment (Sensors)

| Key         | 	Type   | 	Description                                        | 	Android	 | iOS |
|:------------|:--------|:----------------------------------------------------|:----------|:----|
| `lightLux`	 | double	 | Ambient light sensor reading in Lux (Android only). | ✅	        | ❌   |

### 7. fetchLocation (GPS)
| Key          | 	Type   | 	Description                 | 	Android	 | iOS |
|:-------------|:--------|:-----------------------------|:----------|:----|
| `latitude`	  | double	 | Current GPS latitude.        | ✅	        | ✅	  |
| `longitude`	 | double	 | Current GPS longitude.       | ✅	        | ✅	  |
| `altitude`	  | double  | 	Current altitude in meters. | ✅	        | ✅	  |


### 8. fetchMotion (Hardware Physical State)
This category briefly polls the hardware accelerometer and proximity sensors to calculate a real-time physical state.

| Key                      | 	Type  | 	Description                                                         | 	Android	 | iOS |
|:-------------------------|:-------|:---------------------------------------------------------------------|:----------|:----|
| `posture`                | String | Device orientation: "Face Up", "Face Down", "Portrait", "Landscape". | ✅	        | ✅	  |
| `motionState`            | String | Instant hardware heuristic: "Moving" or "Still".                     | ✅	        | ✅	  |
| `proximityCm`            | double | Distance to nearest object (usually 0.0 or 5.0).                     | ✅	        | ✅	  |
| `isCovered`              | bool   | true if proximity is < 2.0cm (e.g., in a pocket or face down).       | ✅	        | ✅	  |
| `accelX, accelY, accelZ` | double | Raw accelerometer forces.                                            | ✅	        | ✅	  |


### 9. fetchActivity (AI Behavioral State)
This category uses the OS-level AI (Google Play Services / Apple CoreMotion) to determine long-term behavior.

| Key                  | 	Type  | 	Description                                                     | 	Android	 | iOS |
|:---------------------|:-------|:-----------------------------------------------------------------|:----------|:----|
| `activityType`       | String | AI prediction: "WALKING", "IN_VEHICLE", "STILL", "RUNNING", etc. | ✅	        | ✅	  |
| `activityConfidence` | String | Certainty level: "HIGH", "MEDIUM", "LOW".                        | ✅	        | ✅	  |

___

#### Implementation Notes for Developers:

* **iOS Limitations:** Apple considers Battery Temperature, Voltage, and Cycle Count to be private user data and does not provide public APIs for them. These fields will consistently return `null` on iOS.

* **Android `cpuTemp`:** This relies on reading system thermal zones. It may return `null` on some heavily locked-down Android distributions or specific kernel configurations.

* **Permissions:** If a platform supports a feature (✅) but the user denies the required permission (Location, Activity, etc.), that specific field will return `null`.


___
## 🏃‍♂️ Understanding motionState vs activityType

Why does this library offer two ways to track movement?

1. **motionState (from `fetchMotion`):** This is a **Manual Heuristic**. It calculates raw G-force math directly from the accelerometer. It has zero latency. If you bump a phone sitting on a desk, motionState will instantly report `"Moving"`.

2. **activityType (from `fetchActivity`):** This is **OS-Level AI**. It uses machine learning over several seconds to guess what the user is doing. If you bump a phone on a desk, the AI will still report `"STILL"` because the user's overall behavior hasn't changed.

By fetching both, developers can cross-reference data. For example, if `motionState == Moving` but `activityType == STILL`, the user is likely sitting at a desk but actively handling their phone.