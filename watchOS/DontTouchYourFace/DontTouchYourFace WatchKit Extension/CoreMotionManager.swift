//
//  CoreMotionManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import CoreMotion

final class SensorManager {
	private init() {}
	static let shared = SensorManager()
	let motionManager = CMMotionManager()
}
