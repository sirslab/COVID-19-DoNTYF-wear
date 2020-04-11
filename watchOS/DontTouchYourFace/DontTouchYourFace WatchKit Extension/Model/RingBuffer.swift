//
//  RingBuffer.swift
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
class RingBuffer<T>: NSObject {
	private(set) var array: [T?]
	private var writeIndex = 0
	private var insertedElementsCount = 0
	private var isFull: Bool {
		return insertedElementsCount >= array.count
	}

	init(count: Int) {
		array = [T?](repeating: nil, count: count)
	}

	func write(_ element: T) {
		array[writeIndex % array.count] = element
		writeIndex += 1
		if !isFull {
			insertedElementsCount += 1
		}
	}
}

extension RingBuffer where T == Double {
	private struct Key {
		static var currentSumKey: UInt8 = 0
	}

	private var currentSum: Double? {
		get {
			guard let currentSum = objc_getAssociatedObject(self, &Key.currentSumKey) as? Double else{
				return nil
			}
			return currentSum
		}

		set {
			objc_setAssociatedObject(self, &Key.currentSumKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	func write(_ element: T) {
		// It may be useful if the buffer is full
		let removedElement = array[writeIndex % array.count]
		array[writeIndex % array.count] = element
		writeIndex += 1

		let isNotFull = insertedElementsCount < array.count
		if isNotFull {
			insertedElementsCount += 1
			currentSum = (currentSum ?? 0) + element
		} else if
			let removedElement = removedElement,
			let currentSum = currentSum
		{
			self.currentSum = currentSum + (element - removedElement)
		} else {
			assertionFailure()
		}
	}

	var average: Double? {
		guard
			let currentSum = currentSum
		else {
			return nil
		}
		return currentSum / Double(insertedElementsCount)
	}

	var slope: Slope {
		guard insertedElementsCount > 1 else {
			return .unknown
		}

		var ups = 0

		(1..<insertedElementsCount).forEach { index in
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

		let isGoingUp = Double(ups) / Double(insertedElementsCount) > 0.5
		return isGoingUp ? .up : .down
	}

	var standardDeviation: Double? {
		guard let average = average else {
			return nil
		}
		
		let count = Double(array.count)
		let sumOfSquaredAvgDiff = array.compactMap{$0}.map { pow($0 - average, 2)}.reduce(0,+)
		let standardDeviation = sqrt(sumOfSquaredAvgDiff / (count - 1))
		return standardDeviation
	}

	var max: Double? {
		return array.compactMap({$0}).max()
	}
}
