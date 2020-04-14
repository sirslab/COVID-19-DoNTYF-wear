//
//  PrivacyInterfaceController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import WatchKit

final class PrivacyInterfaceController: WKInterfaceController {
	private let setupManager = SetupManager.shared
	private let sensorManager = SensorManager.shared
	@IBOutlet private var denyButton: WKInterfaceButton!
	@IBOutlet private var contentLabel: WKInterfaceLabel!

	@IBAction private func didTapDenyButton() {
		// Show the message controller with the denied privacy message
		presentController(withName: MessageInterfaceController.identifier, context: Constant.Message.deniedPrivacy)
	}

	@IBAction private func didTapAcceptButton() {
		// Save the user read accepted the privacy policy
		setupManager.usedDidAcceptPrivacyPolicy()
		//Skip magnetometer calibration if the device doesn't have an integrated magnetometer
		if sensorManager.isMagnetometerAvailable {
			pushController(withName: CalibrationInterfaceController.identifier, context: nil)
		} else {
			WKInterfaceController.reloadRootPageControllers(withNames: [MeasurementInterfaceController.identifier],  contexts: nil, orientation: .vertical, pageIndex: 0)
		}
	}

	override func awake(withContext context: Any?) {
		denyButton.setBackgroundColor(Constant.Color.red)
		contentLabel.setText(Constant.Message.privacyMessage)
	}
}
