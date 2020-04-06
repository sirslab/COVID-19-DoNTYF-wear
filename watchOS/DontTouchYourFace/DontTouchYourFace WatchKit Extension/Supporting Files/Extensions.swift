//
//  Extensions.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import WatchKit

extension WKInterfaceController {
	static var identifier: String {
		return String(describing: self)
	}
}
