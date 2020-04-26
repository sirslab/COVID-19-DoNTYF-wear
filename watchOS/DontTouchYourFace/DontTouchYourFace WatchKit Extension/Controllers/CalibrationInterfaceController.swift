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
	private enum State {
		case environment
		case magnet
	}

	@IBOutlet private var countdownTextLabel: WKInterfaceLabel!
	@IBOutlet private var countdownLabel: WKInterfaceLabel!

	@IBOutlet private var calibrateButton: WKInterfaceButton!
	@IBOutlet private var calibrationLabel: WKInterfaceLabel!

	// The timer for the countdown
	private var timer: Timer?
	// The property which holds the current countdown
	private var countdown = Constant.calibrationCountdown
	// State property used to determine what's the next controller to be pushed
	private var isRecalibration: Bool = false
	// State of the calibration
	private var state: State = .environment
	private let sensorManager: CalibrationInterface = SensorManager.shared

	override func awake(withContext context: Any?) {
		isRecalibration = context as? Bool ?? false
		// Set up the initial UI
		calibrationLabel.setText(Constant.Message.calibrationMessage)
		calibrateButton.setBackgroundColor(Constant.Color.blue)
	}
	
	@IBAction func didTapCalibrate() {
		setupCountdownUI()
		startTimer()
		sensorManager.startMagnetometerCalibration()
	}

	private func setupCountdownUI() {
		switch state {
		case .environment:
			countdownTextLabel.setText(Constant.Message.armAway)
		case .magnet:
			countdownTextLabel.setText(Constant.Message.armClose)
		}
		countdownLabel.setText("\(countdown)")
		updateUI(showCountdown: true)
	}

	private func updateUI(showCountdown: Bool) {
		// Based on the showCountdown value, hide or not some components
		countdownTextLabel.setHidden(!showCountdown)
		countdownLabel.setHidden(!showCountdown)
		calibrateButton.setHidden(showCountdown)
		calibrationLabel.setHidden(showCountdown)
	}

	private func startTimer() {
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounting), userInfo: nil, repeats: true)
	}

	@objc private func updateCounting() {
		guard countdown == 0 else {
			// Generate haptic feedback and update the countdown
			WKInterfaceDevice.current().play(.directionDown)
			countdown -= 1
			countdownLabel.setText("\(countdown)")
			return
		}

		// If the countdown is over
		timer?.invalidate()
		timer = nil

		switch state {
		case .environment:
			// Stop the first magnetometer calibration
			sensorManager.stopMagnetometerCalibrationForStandardDeviation()
			// Update the state and the UI again
			state = .magnet
			countdown = Constant.calibrationCountdown
			calibrationLabel.setText(Constant.Message.secondCalibrationMessage)

			updateUI(showCountdown: false)
		case .magnet:
			// Stop the magnetometer calibration
			sensorManager.stopMagnetometerCalibrationForMaximumValue()
			// If is recalibration, pop the controller and show again the main one
			if isRecalibration {
				pop()
			} else {
				// Otherwise present the MeasurementInterfaceController
				WKInterfaceController.reloadRootPageControllers(
					withNames: [MeasurementInterfaceController.identifier],
					contexts: nil,
					orientation: .vertical,
					pageIndex: 0
				)
			}
		}
	}
}
