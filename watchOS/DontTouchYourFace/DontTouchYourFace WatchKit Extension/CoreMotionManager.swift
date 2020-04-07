//
//  CoreMotionManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import CoreMotion

struct AxisValue {
	let sensorName: String
	let x: Double
	let y: Double
	let z: Double
}

typealias SensorHandler = (AxisValue?, Error?) -> Void

final class SensorManager {
	private init() {}
	static let shared = SensorManager()
	let motionManager = CMMotionManager()

	var isDeviceSupported: Bool {
		#if DEBUG
		return motionManager.isAccelerometerAvailable
		#else
		return motionManager.isMagnetometerAvailable
		#endif
	}

	func startCalibration() {
		motionManager.startDeviceMotionUpdates()
	}

	func stopCalibration() {
		motionManager.stopDeviceMotionUpdates()
	}

	func startContinousDataUpdates(to queue: OperationQueue, withHandler: @escaping SensorHandler) {
		motionManager.startDeviceMotionUpdates(to: queue) { (deviceMotion, error) in
			// Magnetometer's outcome is an error
			if let error = error {
				withHandler(nil, error)
				return
			}

			guard let deviceMotion = deviceMotion else {
				withHandler(nil, nil)
				return
			}

			#if DEBUG
			let axisValue = AxisValue(sensorName: "Accelerometer", x: deviceMotion.userAcceleration.x, y: deviceMotion.userAcceleration.y, z: deviceMotion.userAcceleration.z)
			#else
			let axisValue = AxisValue(sensorName: "Magnetometer", x: deviceMotion.magneticField.field.x, y: deviceMotion.magneticField.field.y, z: deviceMotion.magneticField.field.z)
			#endif
			withHandler(axisValue, nil)
		}
	}

	func stopContinousDataUpdates() {
		motionManager.stopDeviceMotionUpdates()
	}
}
