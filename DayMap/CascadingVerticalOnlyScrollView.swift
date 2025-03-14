//
//  CascadingVerticalOnlyScrollView.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/6/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

class CascadingVerticalOnlyScrollView: NSScrollView {
	override func scrollWheel(with event: NSEvent) {
		if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
			self.nextResponder?.scrollWheel(with: event)
			}
		else {
			super.scrollWheel(with: event)
		}
	}
}
