//
//  SensorData.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 11/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

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
