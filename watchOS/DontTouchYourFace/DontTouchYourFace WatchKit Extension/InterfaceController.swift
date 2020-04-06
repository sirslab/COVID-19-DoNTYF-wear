//
//  InterfaceController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion

final class InterfaceController: WKInterfaceController {
	@IBOutlet private var dataLabel: WKInterfaceLabel!
	private let coreMotionManager = CMMotionManager()

	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
		coreMotionManager.startMagnetometerUpdates(to: .main) { [weak self] (data, error) in
			guard let _self = self else {
				return
			}

			// Magnetometer's outcome is an error
			if let error = error {
				_self.dataLabel.setText("Error: \(error.localizedDescription)")
				return
			}

			// Magnetometer's outcome is a valid measurement
			guard let data = data else {
				print("Error is not nil but no data available!")
				return
			}

			// Raw magnetic field. It means it reports
			// the result of the measurement without filtering out the bias introduced by the device and, in some cases, its surrounding fields.
			let rawMagneticField = data.magneticField
			_self.dataLabel.setText("x: \(rawMagneticField.x), y: \(rawMagneticField.y), z: \(rawMagneticField.z)")
		}
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
