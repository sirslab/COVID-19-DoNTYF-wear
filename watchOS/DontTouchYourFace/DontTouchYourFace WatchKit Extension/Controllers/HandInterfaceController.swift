//
//  HandInterfaceController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import WatchKit
import Foundation

final class HandInterfaceController: WKInterfaceController {
	private enum Constant {
		static let leftHand = "leftHand"
		static let rightHand = "rightHand"
		static let handKey = "handSide"
	}

	@IBAction func didTapLeftHandButton() {
		UserDefaults.standard.set(Constant.leftHand, forKey: Constant.handKey)
		showNextController()
	}

	@IBAction func didTapRightHandButton() {
		UserDefaults.standard.set(Constant.rightHand, forKey: Constant.handKey)
		showNextController()
	}

	private func showNextController() {
		pushController(withName: CalibrationInterfaceController.identifier, context: nil)
	}
}
