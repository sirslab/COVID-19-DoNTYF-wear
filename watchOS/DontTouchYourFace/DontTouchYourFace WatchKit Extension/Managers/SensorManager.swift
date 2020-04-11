//
//  SensorManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import CoreMotion
import WatchKit

final class SensorManager {
	// MARK: - Nested types
	typealias SensorHandler = ([SensorData]?, Error?) -> Void

	enum SensorError: Error {
		case deviceMotionNotAvailable
		case gravityNotAvailable
		case userAccelerationNotAvailable
	}

	// MARK: - Properties
	private var magnetometerBuffer: RingBuffer<Double>
	private var armAngleBuffer: RingBuffer<Double>

	private let queue: OperationQueue = {
		let queue = OperationQueue()
		queue.qualityOfService = .userInteractive
		return queue
	}()

	private lazy var setupManager: SensorsDataProvider = SetupManager()

	private lazy var motionManager: CMMotionManager = {
		let motionManager = CMMotionManager()
		motionManager.deviceMotionUpdateInterval = 1/Constant.sensorDataFrequency
		return motionManager
	}()

	var isMagnetometerAvailable: Bool {
		guard motionManager.isMagnetometerAvailable else {
			#if DEBUG
			return true
			#else
			return false
			#endif
		}
		return true
	}

	lazy var isMagnetometerCollectionDataEnabledFromUser: Bool = {
		guard isMagnetometerAvailable else {
			return false
		}
		return true
	}()

	// MARK: - Init
	static let shared = SensorManager()

	private init() {
		magnetometerBuffer = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
		armAngleBuffer = RingBuffer(count: Int(Constant.sensorDataFrequency * Constant.accelerationCollectionDataSeconds))
	}

	// MARK: - Helper functions
	func startMagnetometerCalibration() {
		magnetometerBuffer = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.magnetometerCollectionDataSeconds)
		motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (deviceMotion, error) in
			guard let _self = self else {
				return
			}

			// Check if there's any error
			if error != nil {
				return
			}

			guard let deviceMotion = deviceMotion else {
				return
			}

			let magnetometerData = _self.sensorData(.magnetometer, deviceMotion: deviceMotion)

			// Guard if there are data from the magnetometer
			guard let notNilMagnetometerData = magnetometerData else {
				return
			}

			_self.magnetometerBuffer.write(notNilMagnetometerData.norm)
		}
	}

	func stopMagnetometerCalibrationForStandardDeviation() {
		stopContinousDataUpdates()

		guard let standardDeviation = magnetometerBuffer.standardDeviation else {
			assertionFailure("Average not available")
			return
		}

		setupManager.setStandardDeviation(standardDeviation)
		print("STDDEV \(standardDeviation)")
	}

	func stopMagnetometerCalibrationForMaximumValue() {
		stopContinousDataUpdates()

		guard
			let max = magnetometerBuffer.max,
			let stddev = setupManager.standardDeviation
		else {
			assertionFailure("Missing calibration parameters")
			return
		}

		let factor = max / stddev
		print(factor)
		setupManager.setMagneticFactor(factor)
	}

	func startContinousDataUpdates(withHandler: SensorHandler? = nil) {
		motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (deviceMotion, error) in
			guard let _self = self else {
				return
			}

			// Call handler to ensure the callback is being propagated on the main queue
			let callHandler: SensorHandler = { deviceMotion, error in
				DispatchQueue.main.async {
					withHandler?(deviceMotion, error)
				}
			}

			// Check if there's any error
			if let error = error {
				callHandler(nil, error)
				return
			}

			guard let deviceMotion = deviceMotion else {
				callHandler(nil, SensorError.deviceMotionNotAvailable)
				return
			}

			// Collect data
			// Gravity contains the angle of the inclination of the arm
			guard
				let gravity = _self.sensorData(.gravity, deviceMotion: deviceMotion),
				let pitch = gravity.pitch
			else {
				callHandler(nil, SensorError.gravityNotAvailable)
				return
			}
			
			_self.armAngleBuffer.write(pitch)

			// From the value of the angles collected inside the buffer,\
			// we can determine the slope of the acceleration
			guard var userAcceleration = _self.sensorData(.userAcceleration, deviceMotion: deviceMotion) else {
				callHandler(nil, SensorError.userAccelerationNotAvailable)
				return
			}

			userAcceleration.slope = _self.armAngleBuffer.slope

			var sensorsData: [SensorData] = [
				gravity,
				userAcceleration
			]

			// Guard if there are data from the magnetometer
			guard var magnetometer = _self.sensorData(.magnetometer, deviceMotion: deviceMotion) else {
				callHandler(sensorsData, nil)
				return
			}

			// If the x component of the gravity is not between a certain range
			// it means the user is not raising the hand and we want to keep collection
			// data from the magnetometer
			let isInContinuosCalibrationMode = !gravity.isAlertConditionVerified

			// If the user wants to collect the magnetometer data
			if _self.isMagnetometerCollectionDataEnabledFromUser {
				// Update the buffer with the new incoming data if it's in calibration mode
				if isInContinuosCalibrationMode {
					_self.magnetometerBuffer.write(magnetometer.norm)
				}
				// Set the average for the magnetometer
				magnetometer.average = _self.magnetometerBuffer.average
				// Append to the list of available sensor's data
				sensorsData.append(magnetometer)
			}
			callHandler(sensorsData, nil)
		}
	}

	func stopContinousDataUpdates() {
		motionManager.stopDeviceMotionUpdates()
	}
}

extension SensorManager {
	func sensorData(_ type: SensorType, deviceMotion: CMDeviceMotion) -> SensorData? {
		switch type {
		case .magnetometer:
			let magnetometer: SensorData? = {
				// If the magnetometer isn't available
				if !motionManager.isMagnetometerAvailable {
					// In debug mode add a fake magnetometer data using the user's acceleration
					#if DEBUG
					return SensorData(
						type: .magnetometer,
						x: deviceMotion.userAcceleration.x,
						y: deviceMotion.userAcceleration.y,
						z: deviceMotion.userAcceleration.z
					)
					#else
					return nil
					#endif
				} else {
					// Otherwhise use the real data
					return SensorData(
						type: .magnetometer,
						x: deviceMotion.magneticField.field.x,
						y: deviceMotion.magneticField.field.y,
						z: deviceMotion.magneticField.field.z
					)
				}
			}()
			return magnetometer
		case .gravity:
			let gravity: SensorData = {
				var gravitySensorData = SensorData(
					type: .gravity,
					x: deviceMotion.gravity.x,
					y: deviceMotion.gravity.y,
					z: deviceMotion.gravity.z
				)

				let pitch: Double = {
					let theta = atan2(-gravitySensorData.x, sqrt(pow(gravitySensorData.y, 2) + pow(gravitySensorData.z, 2))) * (180 / .pi)
					let isOnRightWrist = WKInterfaceDevice.current().wristLocation == .right
					return isOnRightWrist ? -theta : theta
				}()

				gravitySensorData.pitch = pitch
				return gravitySensorData
			}()
			return gravity
		case .userAcceleration:
			let userAcceleration = SensorData(
				type: .userAcceleration,
				x: deviceMotion.gravity.x,
				y: deviceMotion.gravity.y,
				z: deviceMotion.gravity.z
			)
			return userAcceleration
		}
	}
}
