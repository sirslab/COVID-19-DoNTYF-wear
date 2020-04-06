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

final class DetectionManager {
	enum Result {
		case error(String)
		case data(CMAcceleration)
	}

	private let threshold: Double = 1
	private let coreMotionManager: CMMotionManager

	init(coreMotionManager: CMMotionManager) {
		self.coreMotionManager = coreMotionManager
	}

	func collectData(completion: @escaping (Result) -> Void) {
		guard coreMotionManager.isAccelerometerAvailable else{
			completion(.error("Magnetometer not available"))
			return
		}

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

			if deviceMotion.userAcceleration.z > _self.threshold {
				WKInterfaceDevice.current().play(.failure)
			}

			completion(.data(deviceMotion.userAcceleration))
		}
	}
}
