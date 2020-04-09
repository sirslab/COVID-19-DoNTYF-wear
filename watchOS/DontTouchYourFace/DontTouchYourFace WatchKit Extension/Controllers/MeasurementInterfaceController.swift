//
//  InterfaceController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion

final class MeasurementInterfaceController: WKInterfaceController {
	@IBOutlet private var dataLabel: WKInterfaceLabel!

	@IBOutlet private var accelerationThresholdLabel: WKInterfaceLabel!
	@IBOutlet private var accelerationThresholdSlider: WKInterfaceSlider!

	@IBOutlet private var startStopButton: WKInterfaceButton!
	@IBOutlet private var calibrateButton: WKInterfaceButton!

	private let detectionManager = DetectionManager()
	private var crownAccumulator = 0.0

	override func awake(withContext context: Any?) {
        super.awake(withContext: context)

		setupAccelerationThresholdSlider()
		updateAccelerationThreshold(Float(Threshold.Acceleration.accelerationThreshold))

		calibrateButton.setBackgroundColor(Constant.Color.blue)
		dataLabel.setText("Press start")

		crownSequencer.delegate = self

		detectionManager.delegate = self
		detectionManager.sensorCallback = { [weak self] result in
			guard let _self = self else {
				return
			}

			switch result {
			case .error(let errorString):
				_self.dataLabel.setText(errorString)
			case .data(let sensorsData):

				let gravityValues = sensorsData.first { $0.type == .gravity }
				let accelerometerValues = sensorsData.first { $0.type == .userAccelerometer }
				let magnetometerValues = sensorsData.first { $0.type == .magnetometer }

				guard
					let xGravityComponent = gravityValues?.x,
					let zAccelerationComponent = accelerometerValues?.z,
					let magnetometerAverage = magnetometerValues?.average
				else {
					return
				}

				// Check wirst side for asin
				let theha = atan2(-gravityValues!.x, sqrt(pow(gravityValues!.y, 2) + pow(gravityValues!.z, 2))) * (180 / .pi)
				let dataString = String(format: "X Θ: %.2f\nZ acc: %.2f\n M𝜇: %.2f", theha, zAccelerationComponent, magnetometerAverage)
				_self.dataLabel.setText(dataString)
			}
		}
    }

	override func willActivate() {
		super.willActivate()
		crownSequencer.focus()
	}

	private func setupAccelerationThresholdSlider() {
		let steps = (Threshold.Acceleration.maxValue - Threshold.Acceleration.minValue) / Constant.crownStep
		accelerationThresholdSlider.setNumberOfSteps(Int(steps))
	}

	@IBAction private func didChangeSliderValue(_ value: Float) {
		updateAccelerationThreshold(value)
	}

	@IBAction private func didTapStartStop() {
		detectionManager.toggleState()
	}

	@IBAction private func didTapCalibrate() {
		let isRecalibration = true
		pushController(withName: CalibrationInterfaceController.identifier, context: isRecalibration)
	}

	private func updateAccelerationThreshold(_ value: Float) {
		guard value <= Threshold.Acceleration.maxValue && value >= Threshold.Acceleration.minValue else {
			return
		}
		accelerationThresholdLabel.setText("\(value)")
		accelerationThresholdSlider.setValue(value)
		Threshold.Acceleration.accelerationThreshold = value
	}

	private func setStopActivityUI() {
		startStopButton.setBackgroundColor(Constant.Color.green)
		startStopButton.setTitle(Constant.startButtonText)
		dataLabel.setText(Constant.notReadingDataText)
	}

	private func setRunningActivityUI() {
		startStopButton.setBackgroundColor(Constant.Color.red)
		startStopButton.setTitle(Constant.stopButtonText)
		dataLabel.setText("")
	}
}

extension MeasurementInterfaceController: WKCrownDelegate {
	func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
		crownAccumulator += rotationalDelta
		if crownAccumulator > Constant.crownSensitivity {
			updateAccelerationThreshold(Threshold.Acceleration.accelerationThreshold + Constant.crownStep)
		   crownAccumulator = 0.0
		} else if crownAccumulator < -Constant.crownSensitivity {
			updateAccelerationThreshold(Threshold.Acceleration.accelerationThreshold - Constant.crownStep)
		   crownAccumulator = 0.0
		}
	}
}

extension MeasurementInterfaceController: DetectionManagerDelegate {
	func manager(_ manager: DetectionManager, didChangeState state: DetectionManager.State) {
		switch state {
		case .running:
			setRunningActivityUI()
			calibrateButton.setEnabled(false)
		case .stopped:
			setStopActivityUI()
			calibrateButton.setEnabled(true)
		}
	}

	func managerDidRaiseAlert(_ manager: DetectionManager) {
		print("Vibration")
		WKInterfaceDevice.current().play(.failure)
	}
}
