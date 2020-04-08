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
	func managerDidRaiseAlert(_ manager: DetectionManager)
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
		case data([SensorManager.SensorData])
	}

	private let sensorManager: SensorManager
	private let notificationCenter: UNUserNotificationCenter
	private var workoutSession: HKWorkoutSession?

	private var isAlertInAction = false
	private var didEnabledNotification = false

	private lazy var workoutConfiguration: HKWorkoutConfiguration = {
		let workoutConfiguration = HKWorkoutConfiguration()
		workoutConfiguration.activityType = .running
		return workoutConfiguration
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
		sensorManager: SensorManager = SensorManager.shared,
		notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()
	) {
		self.sensorManager = sensorManager
		self.notificationCenter = notificationCenter

		defer {
			notificationCenter.requestAuthorization(options: [.alert, .sound]) { [weak self] (granted, _) in
				self?.didEnabledNotification = granted
			}
		}
	}

	func toggleState() {
		state.toggle()
	}

	private func startCollectingData() {
		guard sensorManager.isDeviceSupported else{
			sensorCallback?(.error(Constant.Message.sensorNotAvailable))
			return
		}

		workoutSession = try? HKWorkoutSession(healthStore: .init(), configuration: workoutConfiguration)
		workoutSession?.startActivity(with: nil)

		sensorManager.startContinousDataUpdates { [weak self] (sensorsData, error) in
			guard let _self = self else {
				return
			}

			// Magnetometer's outcome is an error
			if let error = error {
				_self.sensorCallback?(.error(error.localizedDescription))
				return
			}

			// Magnetometer's outcome is a valid measurement
			guard let sensorsData = sensorsData else {
				_self.sensorCallback?(.error(Constant.Message.internalError))
				return
			}

			if _self.shuoldTriggerAlert(sensorsData: sensorsData) {
				_self.isAlertInAction = true
				_self.delegate?.managerDidRaiseAlert(_self)

				DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
					_self.isAlertInAction = false
				}
			}
			_self.sensorCallback?(.data(sensorsData))
		}
	}

	private func stopCollectingData() {
		sensorManager.stopContinousDataUpdates()
		workoutSession?.end()
	}

	private func shuoldTriggerAlert(sensorsData: [SensorManager.SensorData]) -> Bool {
		let didPreviousTriggerEnd = isAlertInAction == false
		let shouldRaiseAlert: Bool = sensorsData.map { $0.isAlertConditionVerified }.allSatisfy { $0 }
		return didPreviousTriggerEnd && shouldRaiseAlert
	}
}
