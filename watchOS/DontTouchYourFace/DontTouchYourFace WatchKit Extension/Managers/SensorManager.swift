//
//  SensorManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import CoreMotion


final class SensorManager {
	typealias SensorHandler = ([SensorData]?, Error?) -> Void

	enum SensorType {
		case userAccelerometer
		case magnetometer
		case gravity
	}

	struct SensorData {
		let type: SensorType
		let x: Double
		let y: Double
		let z: Double
	}

	private init() {}
	static let shared = SensorManager()

	lazy var motionManager: CMMotionManager = {
		let motionManager = CMMotionManager()
		motionManager.deviceMotionUpdateInterval = 1/50
		return motionManager
	}()

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

			let gravity = SensorData(
				type: .gravity,
				x: deviceMotion.gravity.x,
				y: deviceMotion.gravity.y,
				z: deviceMotion.gravity.z
			)

			let accelerometer = SensorData(
				type: .userAccelerometer,
				x: deviceMotion.userAcceleration.x,
				y: deviceMotion.userAcceleration.y,
				z: deviceMotion.userAcceleration.z
			)

			var sensorsData: [SensorData] = [
				gravity,
				accelerometer
			]

			#if !DEBUG
			let magnetometer = SensorData(
				type: .magnetotemer,
				x: deviceMotion.magneticField.field.x,
				y: deviceMotion.magneticField.field.y,
				z: deviceMotion.magneticField.field.z
			)
			sensorsData.append(contentsOf: magnetometer)
			#endif
			withHandler(sensorsData, nil)
		}
	}

	func stopContinousDataUpdates() {
		motionManager.stopDeviceMotionUpdates()
	}
}
