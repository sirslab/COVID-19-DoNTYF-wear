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
	@IBOutlet private var contentLabel: WKInterfaceLabel!

	@IBAction private func didTapLeftHandButton() {
		// Save the selected hand side
		UserDefaults.standard.set(Hand.left.rawValue, forKey: Constant.handKey)
		showNextController()
	}

	@IBAction private func didTapRightHandButton() {
		// Save the selected hand side
		UserDefaults.standard.set(Hand.right.rawValue, forKey: Constant.handKey)
		showNextController()
	}

	private func showNextController() {
		//Skip magnetometer calibration if the device doesn't have an integrated magnetometer
		if SensorManager.shared.isMagnetometerAvailable {
			pushController(withName: CalibrationInterfaceController.identifier, context: nil)
		} else {
			WKInterfaceController.reloadRootPageControllers(withNames: [MeasurementInterfaceController.identifier],  contexts: nil, orientation: .vertical, pageIndex: 0)
		}
	}

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		contentLabel.setText(Constant.Message.handSelectionMessage)
	}
}
