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

	enum SensorType {
		case userAcceleration
		case magnetometer
		case gravity
	}

	struct SensorData {
		let type: SensorType
		let x: Double
		let y: Double
		let z: Double
		var average: Double? = nil // for magnetometer
		var slope: Slope? = nil
		var pitch: Double? = nil

		var norm: Double {
			let powNorm = pow(x, 2) + pow(y, 2) + pow(z, 2)
			return sqrt(powNorm)
		}

		var isAlertConditionVerified: Bool {
			switch type {
			case .gravity:
				guard let pitch = pitch else {
					return false
				}
				return pitch >= 30 && pitch <= 100
			case .magnetometer:
				guard let average = average else {
					return false
				}
				return average >= 0.15
			case .userAcceleration:
				guard let slope = slope else {
					return false
				}
				return slope == .up
			}
		}
	}

	// MARK: - Properties
	private var magnetometerBuffer: RingBuffer<Double>
	private var slopeBuffer: RingBuffer<Double>

	private let queue: OperationQueue = {
		let queue = OperationQueue()
		queue.qualityOfService = .userInteractive
		return queue
	}()

	private lazy var setupManager = SetupManager()

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
		slopeBuffer = RingBuffer(count: Int(Constant.sensorDataFrequency * Constant.accelerationCollectionDataSeconds))
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

			let magnetometer: SensorData? = {
				// If the magnetometer isn't available
				if !_self.motionManager.isMagnetometerAvailable {
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

			// Guard if there are data from the magnetometer
			guard let notNilMagnetometer = magnetometer else {
				return
			}

			_self.magnetometerBuffer.write(notNilMagnetometer.norm)
		}
	}
	
	func stopMagnetometerCalibrationForMaximumValue() {
		stopContinousDataUpdates()
		let max = magnetometerBuffer.array.compactMap {$0}.max()

		guard max != nil else {
			return
		}

		let stddev = UserDefaults.standard.double(forKey: "STDDEV")
		let factor = max! / stddev
		print("Max \(max!)")
		print(factor)
		UserDefaults.standard.set(factor, forKey: "magneticFactor")
	}

	func stopMagnetometerCalibrationForStandardDeviation() {
		stopContinousDataUpdates()

		guard let average = magnetometerBuffer.average else {
			assertionFailure("Average not available")
			return
		}

		let count = Double(magnetometerBuffer.array.count)
		let sumOfSquaredAvgDiff = magnetometerBuffer.array.compactMap{$0}.map {
			pow($0 - average, 2)
		}.reduce(0,+)
		let standardDeviation = sqrt(sumOfSquaredAvgDiff / (count - 1))
		UserDefaults.standard.set(standardDeviation, forKey: "STDDEV")
		print("STDDEV \(standardDeviation)")
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
				callHandler(nil, nil)
				return
			}

			// Collect data
			// Gravity contains the angle of the inclination of the arm
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
				_self.slopeBuffer.write(pitch)
				return gravitySensorData
			}()

			// From the value of the angles collected inside the buffer,\
			// we can determine the slope of the acceleration
			let userAcceleration = SensorData(
				type: .userAcceleration,
				x: deviceMotion.gravity.x,
				y: deviceMotion.gravity.y,
				z: deviceMotion.gravity.z,
				slope: _self.slopeBuffer.slope
			)

			var sensorsData: [SensorData] = [
				gravity,
				userAcceleration
			]

			let magnetometer: SensorData? = {
				// If the magnetometer isn't available
				if !_self.motionManager.isMagnetometerAvailable {
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

			// Guard if there are data from the magnetometer
			guard var notNilMagnetometer = magnetometer else {
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
					_self.magnetometerBuffer.write(notNilMagnetometer.norm)
				}
				// Set the average for the magnetometer
				notNilMagnetometer.average = _self.magnetometerBuffer.average
				// Append to the list of available sensor's data
				sensorsData.append(notNilMagnetometer)
			}
			callHandler(sensorsData, nil)
		}
	}

	func stopContinousDataUpdates() {
		motionManager.stopDeviceMotionUpdates()
	}
}
