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
	@IBAction private func didTapLeftHandButton() {
		UserDefaults.standard.set(Hand.left.rawValue, forKey: Constant.handKey)
		showNextController()
	}

	@IBAction private func didTapRightHandButton() {
		UserDefaults.standard.set(Hand.right.rawValue, forKey: Constant.handKey)
		showNextController()
	}

	private func showNextController() {
		pushController(withName: CalibrationInterfaceController.identifier, context: nil)
	}
}
