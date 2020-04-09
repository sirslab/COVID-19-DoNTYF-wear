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
	@IBOutlet private var denyButton: WKInterfaceButton!
	
	@IBAction private func didTapDenyButton() {
		// Show the message controller with the denied privacy message
		presentController(withName: MessageInterfaceController.identifier, context: Constant.Message.deniedPrivacy)
	}

	@IBAction private func didTapAcceptButton() {
		// Save the user read accepted the privacy policy
		UserDefaults.standard.set(true, forKey: Constant.grantPermissionKey)
		pushController(withName: HandInterfaceController.identifier, context: nil)
	}

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		denyButton.setBackgroundColor(Constant.Color.red)
	}
}
