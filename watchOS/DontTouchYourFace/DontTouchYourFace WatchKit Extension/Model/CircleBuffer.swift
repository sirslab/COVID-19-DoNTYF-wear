//
//  CircleBuffer.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 08/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

enum Slope: String {
	case up
	case down
	case unknown
}

/// Ring Buffers holds N elements at a time.
/// When the buffer runs out of storage, it starts replacing the longest indersted element and so on
struct RingBuffer<T> {
	private(set) var array: [T?]
	private var writeIndex = 0
	private var itemsCounter = 0

	init(count: Int) {
		array = [T?](repeating: nil, count: count)
	}

	mutating func write(_ element: T) {
		array[writeIndex % array.count] = element
		writeIndex += 1
		if itemsCounter < array.count {
			itemsCounter += 1
		}
	}
}

extension RingBuffer where T == Double {
	var average: Double {
		// Improve time complexity
		return array.compactMap { $0 }.reduce(0, +) / Double(array.count)
	}

	var slope: Slope {
		guard itemsCounter > 1 else {
			return .unknown
		}

		var ups = 0

		(1..<itemsCounter).forEach { index in
			let previous = index - 1

			guard
				let element = array[index],
				let previousElement = array[previous],
				element - previousElement > 0.1
			else {
				return
			}

			ups += 1
		}

		let isGoingUp = Double(ups) / Double(itemsCounter) > 0.5
		return isGoingUp ? .up : .down
	}
}
