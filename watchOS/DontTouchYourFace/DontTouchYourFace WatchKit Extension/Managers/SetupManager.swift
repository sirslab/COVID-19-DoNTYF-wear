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

	init(userDefaults: UserDefaults = .standard) {
		self.userDefaults = userDefaults
	}

	/// Returns if the user has accepted the privacy policy
	var didUserAcceptPrivacy: Bool {
		return userDefaults.bool(forKey: Constant.grantPermissionKey)
	}

	/// Returns if the user has selected on which side he/she wears the watch
	var didUserSelectHand: Bool {
		return userDefaults.string(forKey: Constant.handKey) != nil
	}

	/// Returns the side the user wears the watch on, nil if not selected yet
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
