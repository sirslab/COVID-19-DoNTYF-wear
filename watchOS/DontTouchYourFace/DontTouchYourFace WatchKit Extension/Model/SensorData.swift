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

protocol SensorData {
	var x: Double { get }
	var y: Double { get }
	var z: Double { get }
	var isAlertConditionVerified: Bool { get }
}

struct UserAccelerationData: SensorData {
	let x: Double
	let y: Double
	let z: Double
	var slope: Slope? = nil

	var isAlertConditionVerified: Bool {
		guard let slope = slope else {
			return false
		}
		return slope == .up
	}
}

struct GravityData: SensorData {
	let x: Double
	let y: Double
	let z: Double
	let pitch: Double

	var isAlertConditionVerified: Bool {
		return pitch >= 30 && pitch <= 100
	}
}

struct MagnetometerData: SensorData {
	let x: Double
	let y: Double
	let z: Double
	var average: Double? = nil
	var standardDeviation: Double? = nil
	var factor: Double? = nil

	var norm: Double {
		let powNorm = pow(x, 2) + pow(y, 2) + pow(z, 2)
		return sqrt(powNorm)
	}

	var isAlertConditionVerified: Bool {
		guard
			let average = average,
			let standardDeviation = standardDeviation,
			let factor = factor
		else {
			return false
		}
		return (norm - average) >= factor * standardDeviation
	}
}
