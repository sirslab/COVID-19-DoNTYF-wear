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

protocol DetectionManagerDelegate: AnyObject {
	func manager(_ manager: DetectionManager, didChangeState state: DetectionManager.State)
	func managerDidRaiseAlert(_ manager: DetectionManager)
}

final class DetectionManager {
	// MARK: - Nested types
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

	// MARK: - Properties
	private let sensorManager: SensorManager
	private var workoutSession: HKWorkoutSession?

	// Boolean to avoid multiple recognitions of the alert in a short amount of time
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

	// MARK: - Init
	init(sensorManager: SensorManager = SensorManager.shared) {
		self.sensorManager = sensorManager
	}

	// MARK: - Helper methods
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

			// Sensor's outcome is an error
			if let error = error {
				_self.sensorCallback?(.error(error.localizedDescription))
				return
			}

			guard let sensorsData = sensorsData else {
				_self.sensorCallback?(.error(Constant.Message.internalError))
				return
			}

			// Sensor's outcome is a valid measurement
			// Check if the received data are matching the condition for raising an alert
			if _self.shuoldTriggerAlert(sensorsData: sensorsData) {
				// If yes set that an alert is being sent and inform the delegate
				_self.isAlertInAction = true
				_self.delegate?.managerDidRaiseAlert(_self)

				DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
					// A new alert could be detected
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
