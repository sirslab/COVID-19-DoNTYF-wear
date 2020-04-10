//
//  Constant.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

enum Constant {
	static let grantPermissionKey = "didAcceptPrivacy"
	static let handKey = "handSide"

	static let accelerationCrownStep: Float = 0.01
	static let magneticFieldCrownStep: Float = 0.01
	static let crownSensitivity: Double = 0.1

	static let magnetometerCollectionDataSeconds = 5
	static let accelerationCollectionDataSeconds = 0.25
	static let sensorDataFrequency: Double = 50 // in hz

	static let startButtonText = "Start"
	static let stopButtonText = "Stop"

	static let calibrationCountdown = 5
	static let nextAlertDelay: Double = 1
	
	enum Message {
		static let deniedPrivacy = "Sorry you have to accept the privacy policy to continue to use this app."
		static let internalError = "Error is not nil but no data available!"

		static let calibrationMessage = "After pressing the button, move your hand in front of you for 5 seconds to calibrate the magnetic sensor."
		static let handSelectionMessage = "Do you wear the smartwatch on the left or on the right?"
		static let privacyMessage = """
		This app collects data from the accelerometer and the magnetometer integrated in this device in order to  estimate when the user is approaching his hands towards his face.
		"""
	}

	enum Color {
		static let red = UIColor(red: 234/255, green: 79/255, blue: 58/255, alpha: 1)
		static let green = UIColor(red: 0, green: 144/255, blue: 81/255, alpha: 1)
		static let blue = UIColor(red: 0, green: 122/255, blue: 255/255, alpha: 1)
	}
}
