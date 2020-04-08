//
//  SetupManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import WatchKit

final class SetupManager {
	private let userDefaults: UserDefaults

	init(userDefaults: UserDefaults) {
		self.userDefaults = userDefaults
	}

	var didUserAcceptPrivacy: Bool {
		return userDefaults.bool(forKey: Constant.grantPermissionKey)
	}

	var didUserSelectHand: Bool {
		return userDefaults.string(forKey: Constant.handKey) != nil
	}

	var selectedHand: Hand? {
		guard
			didUserSelectHand,
			let key = userDefaults.string(forKey: Constant.handKey)
		else {
			return nil
		}

		return Hand(rawValue: key)
	}
}
