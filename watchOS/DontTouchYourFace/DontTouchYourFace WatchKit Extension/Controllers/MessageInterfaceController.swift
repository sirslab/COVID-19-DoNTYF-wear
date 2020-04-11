//
//  MessageInterfaceController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import WatchKit

// A controller which shows a message
final class MessageInterfaceController: WKInterfaceController {
	@IBOutlet private var centredLabel: WKInterfaceLabel!

	override func awake(withContext context: Any?) {
		// Show the messaged passed as content
		centredLabel.setText(context as? String)
	}
}
