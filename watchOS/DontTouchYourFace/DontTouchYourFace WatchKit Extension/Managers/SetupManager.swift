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
}
