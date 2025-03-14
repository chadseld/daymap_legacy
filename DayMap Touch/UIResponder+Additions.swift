//
//  UIResponder+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 4/27/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit

//private weak var currentFirstResponder: UIResponder? = nil

extension UIResponder {
	private weak static var currentFirstResponder: UIResponder? = nil

	static var firstResponder: UIResponder? {
		currentFirstResponder = nil
		UIApplication.shared.sendAction(#selector(findFirstResponder(_:)), to: nil, from: nil, for: nil)
		return currentFirstResponder
	}
	
	@objc func findFirstResponder(_ sender: Any) {
		UIResponder.currentFirstResponder = self
	}
}

