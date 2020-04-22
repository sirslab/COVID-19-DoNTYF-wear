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
	@IBOutlet private var armAngleLabel: WKInterfaceLabel!
	@IBOutlet private var armAngleSlider: WKInterfaceSlider!
	@IBOutlet private var minAngleLabel: WKInterfaceLabel!

	@IBOutlet private var userAccelerationLabel: WKInterfaceLabel!

	@IBOutlet private var magneticFieldLabel: WKInterfaceLabel!
	@IBOutlet private var magneticFieldSlider: WKInterfaceSlider!
	@IBOutlet private var magneticFieldNormAvgLabel: WKInterfaceLabel!
	@IBOutlet private var magneticFieldDataGroup: WKInterfaceGroup!
	@IBOutlet private var magneticFieldSliderGroup: WKInterfaceGroup!
	@IBOutlet private var magnetometerToggle: WKInterfaceSwitch!
	@IBOutlet private var magneticFieldSeparator: WKInterfaceSeparator!

	@IBOutlet private var startStopButton: WKInterfaceButton!
	@IBOutlet private var calibrateButton: WKInterfaceButton!

	// MARK: - Properties
	// Used to determine which slider the crown should control
	private var lastTouchedSlider: WKInterfaceSlider?
	private let detectionManager = DetectionManager()
	private let sensorManager = SensorManager.shared
	private let setupManager: SensorsDataProvider = SetupManager.shared

	private var crownAccumulator = 0.0

	// MARK: - Controller Lifecycle
	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		setupUI()
		startDetection()
    }

	override func willActivate() {
		super.willActivate()
		setupUI()
	}

	// MARK: - Helper methods
	private func setupUI() {
		crownSequencer.delegate = self

		if
			sensorManager.isMagnetometerAvailable,
			let userDefinedMagneticFactor = SetupManager.shared.userDefinedMagneticFactor,
			let magneticFactor = setupManager.magneticFactor
		{
			setupMagneticFieldThresholdSlider(magneticFactor: magneticFactor)
			updateMagneticFieldThreshold(Float(userDefinedMagneticFactor))
			calibrateButton.setBackgroundColor(Constant.Color.blue)
		} else {
			magneticFieldDataGroup.setHidden(true)
			magneticFieldSliderGroup.setHidden(true)
			magneticFieldSeparator.setHidden(true)
			calibrateButton.setHidden(true)
			startStopButton.setRelativeWidth(1, withAdjustment: 0)
		}

		let initialAngle = setupManager.userDefinedMinAngle ?? Threshold.Angle.minValue
		setupMinimumAngleThresoldSlider()
		updateMinimumAngleThreshold(initialAngle)
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
				_self.userAccelerationLabel.setText(errorMessage)
				_self.magneticFieldNormAvgLabel.setText(errorMessage)
				// Print the actual error in the console
				print(errorString)

			case .data(let sensorsData):
				// Retrieve the mandatory sensor's data
				guard
					let gravityData = sensorsData.first(where: { $0 is GravityData }) as? GravityData,
					let userAccelerationData = sensorsData.first(where: { $0 is UserAccelerationData }) as? UserAccelerationData,
					let slope = userAccelerationData.slope
				else {
					assertionFailure("This should not happen")
					return
				}

				let pitch = gravityData.pitch
				let magnetometerValues = sensorsData.first { $0 is MagnetometerData} as? MagnetometerData

				// Print values
				let thetaString = String(format: "%.2f", pitch)
				let zAccelerationString = slope.rawValue

				// If the magnetometer's data is present show the value otherwise
				if let magnetometerAverage = magnetometerValues?.average {
					let magneticFieldAverageNormString = String(format: "%.2f", magnetometerAverage)
					_self.magneticFieldNormAvgLabel.setText(magneticFieldAverageNormString)
				} else {
					_self.magneticFieldNormAvgLabel.setText("Not available")
				}

				_self.armAngleLabel.setText(thetaString)
				_self.userAccelerationLabel.setText(zAccelerationString)
			}
		}
	}

	private func setupMagneticFieldThresholdSlider(magneticFactor: Double) {
		let maxValue = Threshold.MagneticField.maxValue + Float(magneticFactor)
		let steps = (maxValue - Threshold.MagneticField.minValue) / Constant.magneticFieldCrownStep
		magneticFieldSlider.setNumberOfSteps(Int(steps))
	}

	private func setupMinimumAngleThresoldSlider() {
		let minValue = Threshold.Angle.minValue
		let maxValue = Threshold.Angle.maxValue
		let steps = Int(maxValue - minValue)
		armAngleSlider.setNumberOfSteps(steps)
	}

	private func updateMinimumAngleThreshold(_ value: Float) {
		guard value <= Threshold.Angle.maxValue && value >= Threshold.Angle.minValue else {
			WKInterfaceDevice.current().play(.failure)
			return
		}

		WKInterfaceDevice.current().play(.click)
		let thresholdString = String(format: "Min Angle %.2f°", value)
		minAngleLabel.setText(thresholdString)
		armAngleSlider.setValue(value)
		setupManager.setUserDefinedMinAngle(value)
		sensorManager.userDefinedMinAngle = value
	}

	private func updateMagneticFieldThreshold(_ value: Float) {
		let maxValue = Threshold.MagneticField.maxValue + value

		guard value <= maxValue && value >= Threshold.MagneticField.minValue else {
			WKInterfaceDevice.current().play(.failure)
			return
		}

		WKInterfaceDevice.current().play(.click)
		let thresholdString = String(format: "Mag Factor %.2f", value)
		magneticFieldLabel.setText(thresholdString)
		magneticFieldSlider.setValue(value)
		setupManager.setUserDefinedMagneticFactor(Double(value))
		sensorManager.userDefinedMagneticFactor = Double(value)
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
	@IBAction func didChangeMagneticFieldSliderValue(_ value: Float) {
		lastTouchedSlider = magneticFieldSlider
		crownSequencer.focus()
		updateMagneticFieldThreshold(value)
	}

	@IBAction func didChangeMinAngleSliderValue(_ value: Float) {
		lastTouchedSlider = armAngleSlider
		crownSequencer.focus()
		updateMinimumAngleThreshold(value)
	}

	@IBAction private func didTapStartStop() {
		detectionManager.toggleState()
	}

	@IBAction private func didTapCalibrate() {
		let isRecalibration = true
		pushController(withName: CalibrationInterfaceController.identifier, context: isRecalibration)
	}

	@IBAction func didTapMagnetometerToggle(_ value: Bool) {
		let didEnableMagnetometer = value
		sensorManager.isMagnetometerCollectionDataEnabledFromUser = didEnableMagnetometer
		magneticFieldSlider.setEnabled(didEnableMagnetometer)

		// Magnetometer disabled
		if !didEnableMagnetometer {
			crownSequencer.resignFocus()
		}
	}

	@IBAction private func didTapAboutUs() {
		pushController(withName: "AboutUs", context: nil)
	}
}

extension MeasurementInterfaceController: WKCrownDelegate {
	func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
		crownAccumulator += rotationalDelta

		switch lastTouchedSlider {
		case magneticFieldSlider:
			guard let userDefinedMagneticFactor = setupManager.userDefinedMagneticFactor else {
				return
			}

			if crownAccumulator > Constant.crownSensitivity {
				updateMagneticFieldThreshold(Float(userDefinedMagneticFactor) + Constant.magneticFieldCrownStep)
			   crownAccumulator = 0.0
			} else if crownAccumulator < -Constant.crownSensitivity {
				updateMagneticFieldThreshold(Float(userDefinedMagneticFactor) - Constant.magneticFieldCrownStep)
			   crownAccumulator = 0.0
			}
		case armAngleSlider:
			guard let userDefinedMinAngle = setupManager.userDefinedMinAngle else {
				return
			}
			if crownAccumulator > Constant.crownSensitivity {
				updateMinimumAngleThreshold(userDefinedMinAngle + 1)
				crownAccumulator = 0.0
			} else if crownAccumulator < -Constant.crownSensitivity {
				updateMinimumAngleThreshold(userDefinedMinAngle - 1)
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
