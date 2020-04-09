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
	// MARK: - Outlets and properties
	// Labels for the data
	@IBOutlet private var armAngleLabel: WKInterfaceLabel!
	@IBOutlet private var zAccelerationLabel: WKInterfaceLabel!
	@IBOutlet private var magneticFieldNormAvgLabel: WKInterfaceLabel!

	// Label and slider for the thresholds
	@IBOutlet private var accelerationThresholdLabel: WKInterfaceLabel!
	@IBOutlet private var accelerationThresholdSlider: WKInterfaceSlider!

	@IBOutlet private var magneticFieldLabel: WKInterfaceLabel!
	@IBOutlet private var magneticFieldSlider: WKInterfaceSlider!

	@IBOutlet private var startStopButton: WKInterfaceButton!
	@IBOutlet private var calibrateButton: WKInterfaceButton!

	// MARK: - Properties
	private let detectionManager = DetectionManager()
	// Used to determine which slider the crown should control
	private var lastTouchedSlider: WKInterfaceSlider?
	private var crownAccumulator = 0.0

	// MARK: - Controller Lifecycle
	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		setupUI()
		setupInitialValue()
		startDetection()
    }

	// MARK: - Helper methods
	private func setupUI() {
		crownSequencer.delegate = self
		setupAccelerationThresholdSlider()
		setupMagneticFieldThresholdSlider()
		calibrateButton.setBackgroundColor(Constant.Color.blue)
	}

	private func setupInitialValue() {
		updateAccelerationThreshold(Threshold.Acceleration.accelerationThreshold)
		updateMagneticFieldThreshold(Threshold.MagneticField.magneticFieldThreshold)
	}

	private func startDetection() {
		detectionManager.delegate = self

		// Start receiving data from the detection manager
		detectionManager.sensorCallback = { [weak self] result in
			guard let _self = self else {
				return
			}

			switch result {
			case .error(let errorString):
				// Show error message
				let errorMessage = "Error"
				_self.armAngleLabel.setText(errorMessage)
				_self.zAccelerationLabel.setText(errorMessage)
				_self.magneticFieldNormAvgLabel.setText(errorMessage)
				// Print the actual error in the console
				print(errorString)
			case .data(let sensorsData):
				// Retrieve the mandatory sensor's data
				let gravityValues = sensorsData.first { $0.type == .gravity }
				let accelerometerValues = sensorsData.first { $0.type == .userAccelerometer }
				let magnetometerValues = sensorsData.first { $0.type == .magnetometer }

				guard
					let gravityComponents = gravityValues,
					let zAccelerationComponent = accelerometerValues?.z
				else {
					return
				}

				// TODO: Check wirst side for asin
				let theha = atan2(-gravityComponents.x, sqrt(pow(gravityComponents.y, 2) + pow(gravityComponents.z, 2))) * (180 / .pi)

				// Print values
				let thetaString = String(format: "%.2f", theha)
				let zAccelerationString = String(format: "%.2f", zAccelerationComponent)

				// If the magnetometer's data is present show the value otherwise
				if let magnetometerAverage = magnetometerValues?.average {
					let magneticFieldAverageNormString = String(format: "%.2f", magnetometerAverage)
					_self.magneticFieldNormAvgLabel.setText(magneticFieldAverageNormString)
				} else {
					_self.magneticFieldNormAvgLabel.setText("Not available")
				}

				_self.armAngleLabel.setText(thetaString)
				_self.zAccelerationLabel.setText(zAccelerationString)
			}
		}
	}

	private func setupAccelerationThresholdSlider() {
		let steps = (Threshold.Acceleration.maxValue - Threshold.Acceleration.minValue) / Constant.crownStep
		accelerationThresholdSlider.setNumberOfSteps(Int(steps))
	}

	private func setupMagneticFieldThresholdSlider() {
		let steps = (Threshold.MagneticField.maxValue - Threshold.MagneticField.minValue) / Constant.crownStep
		magneticFieldSlider.setNumberOfSteps(Int(steps))
	}

	private func updateAccelerationThreshold(_ value: Float) {
		guard value <= Threshold.Acceleration.maxValue && value >= Threshold.Acceleration.minValue else {
			WKInterfaceDevice.current().play(.failure)
			return
		}

		WKInterfaceDevice.current().play(.click)
		let thresholdString = String(format: "Z Acc Thr %.2f", value)
		accelerationThresholdLabel.setText(thresholdString)
		accelerationThresholdSlider.setValue(value)
		Threshold.Acceleration.accelerationThreshold = value
	}

	private func updateMagneticFieldThreshold(_ value: Float) {
		guard value <= Threshold.MagneticField.maxValue && value >= Threshold.MagneticField.minValue else {
			WKInterfaceDevice.current().play(.failure)
			return
		}

		WKInterfaceDevice.current().play(.click)
		let thresholdString = String(format: "M𝜇 Thr %.2f", value)
		magneticFieldLabel.setText(thresholdString)
		magneticFieldSlider.setValue(value)
		Threshold.MagneticField.magneticFieldThreshold = value
	}

	private func setStopActivityUI() {
		startStopButton.setBackgroundColor(Constant.Color.green)
		startStopButton.setTitle(Constant.startButtonText)
	}

	private func setRunningActivityUI() {
		startStopButton.setBackgroundColor(Constant.Color.red)
		startStopButton.setTitle(Constant.stopButtonText)
	}

	// MARK: - Actions
	@IBAction private func didChangeAccelerationSliderValue(_ value: Float) {
		lastTouchedSlider = accelerationThresholdSlider
		crownSequencer.focus()
		updateAccelerationThreshold(value)
	}

	@IBAction func didChangeMagneticFieldSliderValue(_ value: Float) {
		lastTouchedSlider = magneticFieldSlider
		crownSequencer.focus()
		updateMagneticFieldThreshold(value)
	}

	@IBAction private func didTapStartStop() {
		detectionManager.toggleState()
	}

	@IBAction private func didTapCalibrate() {
		let isRecalibration = true
		pushController(withName: CalibrationInterfaceController.identifier, context: isRecalibration)
	}
}

extension MeasurementInterfaceController: WKCrownDelegate {
	func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
		crownAccumulator += rotationalDelta

		switch lastTouchedSlider {
		case accelerationThresholdSlider?:
			if crownAccumulator > Constant.crownSensitivity {
				updateAccelerationThreshold(Threshold.Acceleration.accelerationThreshold + Constant.crownStep)
			   crownAccumulator = 0.0
			} else if crownAccumulator < -Constant.crownSensitivity {
				updateAccelerationThreshold(Threshold.Acceleration.accelerationThreshold - Constant.crownStep)
			   crownAccumulator = 0.0
			}
		case magneticFieldSlider?:
			if crownAccumulator > Constant.crownSensitivity {
				updateMagneticFieldThreshold(Threshold.MagneticField.magneticFieldThreshold + Constant.crownStep)
			   crownAccumulator = 0.0
			} else if crownAccumulator < -Constant.crownSensitivity {
				updateMagneticFieldThreshold(Threshold.MagneticField.magneticFieldThreshold - Constant.crownStep)
			   crownAccumulator = 0.0
			}
		default:
			break
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
		DispatchQueue.global(qos: .userInteractive).async {
			print("Vibration")
			WKInterfaceDevice.current().play(.failure)
		}
	}
}
