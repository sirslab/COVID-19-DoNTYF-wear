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

	private var timer: Timer?
	private var countdown = Constant.calibrationCountdown
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
			timer?.invalidate()

			if isRecalibration {
				pop()
			} else {
				WKInterfaceController.reloadRootPageControllers(withNames: [MeasurementInterfaceController.identifier],  contexts: nil, orientation: .vertical, pageIndex: 0)
			}

			SensorManager.shared.stopMagnetometerCalibration()
			return
		}
		WKInterfaceDevice.current().play(.directionDown)
		countdown -= 1
		countdownLabel.setText("\(countdown)")
	}
}
