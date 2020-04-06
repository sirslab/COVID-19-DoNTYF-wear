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

final class DetectionManager {
	enum Result {
		case error(String)
		case data(CMAcceleration)
	}

	private let threshold: Double = 0.3
	private let coreMotionManager: CMMotionManager
	private let notificationCenter: UNUserNotificationCenter

	private var didRecognizeMovement = false

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

	init(
		coreMotionManager: CMMotionManager = SensorManager.shared.motionManager,
		notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()
	) {
		self.coreMotionManager = coreMotionManager
		self.notificationCenter = notificationCenter
	}

	func collectData(completion: @escaping (Result) -> Void) {
		guard coreMotionManager.isAccelerometerAvailable else{
			completion(.error("Magnetometer not available"))
			return
		}

		notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
			// Enable or disable features based on authorization.
		}

		let workoutSession = try? HKWorkoutSession(healthStore: .init(), configuration: workoutConfiguration)
		workoutSession?.startActivity(with: nil)

		coreMotionManager.startDeviceMotionUpdates(to: .main) { [weak self] (deviceMotion, error) in
			guard let _self = self else {
				return
			}
			// Magnetometer's outcome is an error
			if let error = error {
				completion(.error(error.localizedDescription))
				return
			}

			// Magnetometer's outcome is a valid measurement
			guard let deviceMotion = deviceMotion else {
				completion(.error("Error is not nil but no data available!"))
				return
			}

			if deviceMotion.userAcceleration.z > _self.threshold && _self.didRecognizeMovement == false {
				_self.didRecognizeMovement = true

				let id = String(Date().timeIntervalSinceReferenceDate)
				let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.01, repeats: false)

				let request = UNNotificationRequest(identifier: id, content: _self.contentNotification, trigger: trigger)
				_self.notificationCenter.add(request) { _ in
					DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
						_self.didRecognizeMovement = false
					}
				}

				WKInterfaceDevice.current().play(.failure)
				_self.didRecognizeMovement = false

			}

			completion(.data(deviceMotion.userAcceleration))
		}
	}
}
