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
	@IBAction func didTapDenyButton() {
		// present a message
	}

	@IBAction func didTapAcceptButton() {
		UserDefaults.standard.set(true, forKey: Constant.grantPermissionKey)
		pushController(withName: HandInterfaceController.identifier, context: nil)
	}
}
