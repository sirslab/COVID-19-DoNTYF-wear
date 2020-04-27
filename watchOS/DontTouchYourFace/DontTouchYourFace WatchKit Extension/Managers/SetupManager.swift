//
//  SetupManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import WatchKit

protocol OnboardingProvider {
	var didUserAcceptPrivacy: Bool { get }
	var didUserMakeFirstCalibration: Bool { get }
	func usedDidAcceptPrivacyPolicy()
}

protocol SensorsDataProvider {
	var magneticFactor: Double? { get }
	var userDefinedMagneticFactor: Double? { get }
	var standardDeviation: Double? { get }
	var userDefinedMinAngle: Float? { get }
	func setMagneticFactor(_ factor: Double)
	func setStandardDeviation(_ standardDeviation: Double)
	func setUserDefinedMagneticFactor(_ factor: Double)
	func setUserDefinedMinAngle(_ angle: Float)
}

final class SetupManager: OnboardingProvider, SensorsDataProvider {
	private let userDefaults: UserDefaults

	static let shared: SetupManager = SetupManager()
	private init() {
		self.userDefaults = .standard
	}

	/// Returns if the user has accepted the privacy policy
	var didUserAcceptPrivacy: Bool {
		return userDefaults.bool(forKey: Constant.grantPermissionKey)
	}

	/// Returns if the user has completed the calibration the first time
	var didUserMakeFirstCalibration: Bool {
		return magneticFactor != nil
	}

	/// Returns the magnetic factor calculated over the first calibration
	var magneticFactor: Double? {
		let magneticFactor = userDefaults.double(forKey: "magneticFactor")
		guard magneticFactor != 0 else {
			return nil
		}
		return magneticFactor
	}

	/// Returns the adjusted magnetic factor by the user
	var userDefinedMagneticFactor: Double? {
		let userDefinedMagneticFactor = userDefaults.double(forKey: "userDefinedMagneticFactor")
		guard userDefinedMagneticFactor != 0 else {
			return nil
		}
		return userDefinedMagneticFactor
	}

	/// Returns the standard deviation calculated over the first calibration
	var standardDeviation: Double? {
		let standardDeviation = userDefaults.double(forKey: "STDDEV")
		guard standardDeviation != 0 else {
			return nil
		}
		return standardDeviation
	}

	var userDefinedMinAngle: Float? {
		let userDefinedMinAngle = userDefaults.float(forKey: "userDefinedMinAngle")
		guard userDefinedMinAngle != 0 else {
			return nil
		}
		return userDefinedMinAngle
	}

	func usedDidAcceptPrivacyPolicy() {
		userDefaults.set(true, forKey: Constant.grantPermissionKey)
	}

	func setMagneticFactor(_ factor: Double) {
		userDefaults.set(factor, forKey: "magneticFactor")
	}

	func setUserDefinedMagneticFactor(_ factor: Double) {
		userDefaults.set(factor, forKey: "userDefinedMagneticFactor")
	}

	func setStandardDeviation(_ standardDeviation: Double) {
		userDefaults.set(standardDeviation, forKey: "STDDEV")
	}

	func setUserDefinedMinAngle(_ angle: Float) {
		userDefaults.set(angle, forKey: "userDefinedMinAngle")
	}
}
