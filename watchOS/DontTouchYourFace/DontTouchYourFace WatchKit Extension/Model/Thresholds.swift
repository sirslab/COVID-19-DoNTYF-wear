//
//  Thresholds.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 08/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

enum Threshold {
	enum Acceleration {
		static var accelerationThreshold: Float = 0.15
		static let minValue: Float = 0.15
		static let maxValue: Float = 0.5
	}

	enum MagneticField {
		static let minValue: Float = 0
		static let maxValue: Float = 0.90
		static var magneticFieldThreshold: Float = 0.15
	}

	enum Angle {
		static let minValue: Float = 20
		static let maxValue: Float = 90
	}
}
