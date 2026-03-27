import Flutter
import UIKit
import CoreLocation
import CoreMotion

public class DeviceContextPlugin: NSObject, FlutterPlugin {
  private let motionManager = CMMotionManager()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "max.device.collector/context", binaryMessenger: registrar.messenger())
    let instance = DeviceContextPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getSensorData" {
      var data = [String: Any]()
      let args = call.arguments as? [String: Any]
      let fetchDeviceInfo = args?["fetchDeviceInfo"] as? Bool ?? true
      let fetchBasic = args?["fetchBasic"] as? Bool ?? true
      let fetchThermal = args?["fetchThermal"] as? Bool ?? true
      let fetchLocation = args?["fetchLocation"] as? Bool ?? false
      let fetchMotion = args?["fetchMotion"] as? Bool ?? false

      if fetchDeviceInfo { fetchDeviceInfoData(&data) }
      if fetchBasic { fetchBasicInfo(&data) }
      if fetchThermal { fetchThermalInfo(&data) }
      if fetchLocation { fetchLocationInfo(&data) }

      if fetchMotion {
        fetchMotionInfo(&data)
      }

      result(data)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  // --- PRIVATE HELPERS ---

  private func fetchDeviceInfoData(_ data: inout [String: Any]) {
    data["manufacturer"] = "Apple"
    data["osName"] = UIDevice.current.systemName
    data["osVersion"] = UIDevice.current.systemVersion

    // IDFV survives uninstalls (unless user uninstalls all apps from this vendor)
    data["deviceId"] = UIDevice.current.identifierForVendor?.uuidString

    // Extract exact hardware model (e.g., "iPhone14,2")
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let modelIdentifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    data["model"] = modelIdentifier
  }

  private func fetchBasicInfo(_ data: inout [String: Any]) {
    UIDevice.current.isBatteryMonitoringEnabled = true
    data["batteryLevel"] = Int(UIDevice.current.batteryLevel * 100)

    switch UIDevice.current.batteryState {
    case .charging: data["status"] = 2
    case .unplugged: data["status"] = 3
    case .full: data["status"] = 5
    case .unknown: break
    @unknown default: break
    }
  }

  private func fetchThermalInfo(_ data: inout [String: Any]) {
    if #available(iOS 11.0, *) {
      let state = ProcessInfo.processInfo.thermalState
      switch state {
      case .nominal: data["thermalStatus"] = 0
      case .fair: data["thermalStatus"] = 1
      case .serious: data["thermalStatus"] = 3
      case .critical: data["thermalStatus"] = 4
      @unknown default: break
      }
    }
  }

  private func fetchLocationInfo(_ data: inout [String: Any]) {
    let loc = CLLocationManager().location
    if let l = loc {
      data["latitude"] = l.coordinate.latitude
      data["longitude"] = l.coordinate.longitude
      data["altitude"] = l.altitude
    }
  }

  private func fetchMotionInfo(_ data: inout [String: Any]) {
    // 1. Proximity
    UIDevice.current.isProximityMonitoringEnabled = true
    data["isCovered"] = UIDevice.current.proximityState
    UIDevice.current.isProximityMonitoringEnabled = false

    // 2. Posture
    data["posture"] = {
      switch UIDevice.current.orientation {
      case .faceUp: return "Face Up"
      case .faceDown: return "Face Down"
      case .portrait, .portraitUpsideDown: return "Portrait"
      case .landscapeLeft, .landscapeRight: return "Landscape"
      default: return "Other"
      }
    }()

    // 3. Accelerometer (Start updates briefly to grab latest data)
    if motionManager.isAccelerometerAvailable {
      motionManager.startAccelerometerUpdates()
      if let accel = motionManager.accelerometerData {
        let x = accel.acceleration.x
        let y = accel.acceleration.y
        let z = accel.acceleration.z

        data["accelX"] = x
        data["accelY"] = y
        data["accelZ"] = z

        // Manual Heuristic for "Motion"
        let mag = sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2))
        data["motionState"] = abs(mag - 1.0) > 0.1 ? "Moving" : "Still"
      }
      motionManager.stopAccelerometerUpdates()
    }
  }
}