//
//  Color+WS.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/28/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Foundation
#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

#if os(iOS)
	typealias WSColor = UIColor
#else
	typealias WSColor = NSColor
#endif

extension WSColor {
	static var dayMapBlue: WSColor {
		return WSColor(red: 0.03, green: 0.57, blue: 0.73, alpha: 1.0)
	}
	
	static var randomProject: WSColor {
		let prefKey = "com.whetstone.daymap.pref.randprojectcolor"
		var hue: CGFloat = UserDefaults.standard.value(forKey: prefKey) as? CGFloat ?? 0
		let color = WSColor(hue: hue, saturation: 0.80, brightness: 0.93, alpha: 1.0)
		hue = hue + 0.18
		if hue > 1 {
			hue = hue - 1
		}
		UserDefaults.standard.set(hue, forKey: prefKey)
		return color
	}
	
	static var tableBackground: WSColor {
		return WSColor.white
	}
	
	static var alternateTableBackground: WSColor {
		#if os(iOS)
		return WSColor(white: 0.96, alpha: 1)
		#else
		return WSColor(calibratedWhite: 0.96, alpha: 1)
		#endif
	}
}
