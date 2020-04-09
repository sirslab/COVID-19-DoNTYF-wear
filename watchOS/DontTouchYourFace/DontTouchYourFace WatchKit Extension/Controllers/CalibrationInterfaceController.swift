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
	@IBOutlet private var countdownLabel: WKInterfaceLabel!
	@IBOutlet private var calibrateButton: WKInterfaceButton!
	@IBOutlet private var calibrationLabel: WKInterfaceLabel!

	// The timer for the countdown
	private var timer: Timer?
	// The property which holds the current countdown
	private var countdown = Constant.calibrationCountdown
	// State property used to determine what's the next controller to be pushed
	private var isRecalibration: Bool = false

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		if let isRecalibration = context as? Bool {
			self.isRecalibration = isRecalibration
		}
		calibrateButton.setBackgroundColor(Constant.Color.blue)
	}
	
	@IBAction func didTapCalibrate() {
		setupCountdownUI()
		startTimer()
		// Enable reception of the sensors' data and calibrate the magnetometer
		SensorManager.shared.startMagnetometerCalibration()
	}

	private func setupCountdownUI() {
		countdownLabel.setText("\(countdown)")
		countdownLabel.setHidden(false)
		calibrateButton.setHidden(true)
		calibrationLabel.setHidden(true)
	}

	private func startTimer() {
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounting), userInfo: nil, repeats: true)
	}

	@objc private func updateCounting() {
		guard countdown != 0 else {
			// If the countdown is over
			timer?.invalidate()
			timer = nil

			// If is recalibration, pop the controller and show again the main one
			if isRecalibration {
				pop()
			} else {
			// Otherwise present the MeasurementInterfaceController
				WKInterfaceController.reloadRootPageControllers(withNames: [MeasurementInterfaceController.identifier],  contexts: nil, orientation: .vertical, pageIndex: 0)
			}

			// Stop the magnetometer calibration
			SensorManager.shared.stopMagnetometerCalibration()
			return
		}
		// Generate haptic feedback and update the countdown
		WKInterfaceDevice.current().play(.directionDown)
		countdown -= 1
		countdownLabel.setText("\(countdown)")
	}
}
