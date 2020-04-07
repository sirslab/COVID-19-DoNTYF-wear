//
//  Constant.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

enum Constant {
	static let grantPermissionKey = "didAcceptPrivacy"
	static let leftHand = "leftHand"
	static let rightHand = "rightHand"
	static let handKey = "handSide"

	static let initialThreshold: Float = 0.5
	// Change min from IB as well
	static let minValue: Float = 0
	static let maxValue: Float = 5
	static let step: Float = 0.5

	static let crownSensitivity: Double = 0.1

	enum Message {
		static let deniedPrivacy = "Sorry you have to accept the privacy policy to continue to use this app."
		static let unsopportedDevice = "Sorry your device is not supported"
	}
}
