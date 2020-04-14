//
//  Thresholds.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 08/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

enum Threshold {
	enum MagneticField {
		static let minValue: Float = 0
		static let maxValue: Float = 10
	}

	enum Angle {
		static let minValue: Float = 30
		static let maxValue: Float = 90
	}
}
