//
//  DetectionManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import WatchKit
import CoreMotion
import HealthKit
import UserNotifications

protocol DetectionManagerDelegate: AnyObject {
	func manager(_ manager: DetectionManager, didChangeState state: DetectionManager.State)
}

final class DetectionManager {
	enum State {
		case running
		case stopped

		mutating func toggle() {
			switch self {
			case .running:
				self = .stopped
			case .stopped:
				self = .running
			}
		}
	}

	enum Result {
		case error(String)
		case data(CMAcceleration)
	}

	private(set) var threshold: Float
	private let coreMotionManager: CMMotionManager
	private let notificationCenter: UNUserNotificationCenter
	private var workoutSession: HKWorkoutSession?

	private var didRecognizeMovement = false
	private var didEnabledNotification = false

	private lazy var workoutConfiguration: HKWorkoutConfiguration = {
		let workoutConfiguration = HKWorkoutConfiguration()
		workoutConfiguration.activityType = .running
		return workoutConfiguration
	}()

	private lazy var contentNotification: UNMutableNotificationContent = {
		let content = UNMutableNotificationContent()
		content.title = "Hey"
		content.body = "Don't touch your face!"
		content.sound = UNNotificationSound.default
		content.categoryIdentifier = "REMINDER_CATEGORY"
		return content
	}()

	private(set) var state: State = .stopped {
		didSet {
			switch state {
			case .running:
				startCollectingData()
			case .stopped:
				stopCollectingData()
			}
			delegate?.manager(self, didChangeState: state)

		}
	}
	
	var sensorCallback: ((Result) -> Void)?
	weak var delegate: DetectionManagerDelegate?

	init(
		coreMotionManager: CMMotionManager = SensorManager.shared.motionManager,
		notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current(),
		threshold: Float
	) {
		self.coreMotionManager = coreMotionManager
		self.notificationCenter = notificationCenter
		self.threshold = threshold

		defer {
			notificationCenter.requestAuthorization(options: [.alert, .sound]) { [weak self] (granted, _) in
				self?.didEnabledNotification = granted
			}
		}
	}

	func setThreshold(_ value: Float) {
		threshold = value
	}

	func toggleState() {
		state.toggle()
	}

	private func startCollectingData() {
		guard coreMotionManager.isAccelerometerAvailable else{
			sensorCallback?(.error("Magnetometer not available"))
			return
		}

		workoutSession = try? HKWorkoutSession(healthStore: .init(), configuration: workoutConfiguration)
		workoutSession?.startActivity(with: nil)

		coreMotionManager.startDeviceMotionUpdates(to: .main) { [weak self] (deviceMotion, error) in
			guard let _self = self else {
				return
			}
			// Magnetometer's outcome is an error
			if let error = error {
				_self.sensorCallback?(.error(error.localizedDescription))
				return
			}

			// Magnetometer's outcome is a valid measurement
			guard let deviceMotion = deviceMotion else {
				_self.sensorCallback?(.error("Error is not nil but no data available!"))
				return
			}

			if deviceMotion.userAcceleration.z > Double(_self.threshold) && _self.didRecognizeMovement == false {
				_self.didRecognizeMovement = true

				let id = String(Date().timeIntervalSinceReferenceDate)
				let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.01, repeats: false)

				let request = UNNotificationRequest(identifier: id, content: _self.contentNotification, trigger: trigger)
				_self.notificationCenter.add(request) { _ in
					DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
						print("Notification")
						_self.didRecognizeMovement = false
					}
				}

				print("Vibration")
				WKInterfaceDevice.current().play(.failure)
				_self.didRecognizeMovement = false

			}
			_self.sensorCallback?(.data(deviceMotion.userAcceleration))
		}
	}

	private func stopCollectingData() {
		coreMotionManager.stopDeviceMotionUpdates()
		workoutSession?.end()
	}
}
