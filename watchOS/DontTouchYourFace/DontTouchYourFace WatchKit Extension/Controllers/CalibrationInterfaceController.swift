//
//  CalibrationInterfaceController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion

final class CalibrationInterfaceController: WKInterfaceController {
	@IBOutlet var countdownLabel: WKInterfaceLabel!
	@IBOutlet var calibrateButton: WKInterfaceButton!
	@IBOutlet var calibrationLabel: WKInterfaceLabel!

	private var timer: Timer?
	private var countdown = 5

	@IBAction func didTapCalibrate() {
		countdownLabel.setText("\(countdown)")

		countdownLabel.setHidden(false)
		calibrateButton.setHidden(true)
		calibrationLabel.setHidden(true)
		startTimer()
		SensorManager.shared.motionManager.startDeviceMotionUpdates()
	}

	private func startTimer() {
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounting), userInfo: nil, repeats: true)
	}

	@objc private func updateCounting() {
		guard countdown != 0 else {
			timer?.invalidate()
			pushController(withName: MeasurementInterfaceController.identifier, context: nil)
			SensorManager.shared.motionManager.stopDeviceMotionUpdates()
			return
		}
		countdown -= 1
		countdownLabel.setText("\(countdown)")
	}
}
