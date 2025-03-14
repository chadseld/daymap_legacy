//
//  DragHandleView.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/7/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

@objc protocol DragHandleViewDelegate: class {
	func dragHandleView(_ dragHandleView: DragHandleView, didDragFrom from: NSPoint, to: NSPoint)
}

class DragHandleView: NSView {

	@IBOutlet weak var delegate: DragHandleViewDelegate?
	
	// MARK: - Private
	
	private var startPoint: NSPoint = NSZeroPoint
	
	override func resetCursorRects() {
		super.resetCursorRects()
		addCursorRect(bounds, cursor: .resizeLeftRight)
	}
	
	override func mouseDown(with event: NSEvent) {
		let location = convert(event.locationInWindow, from: nil)
		startPoint = location
	}
	
	override func mouseDragged(with event: NSEvent) {
		let location = convert(event.locationInWindow, from: nil)
		delegate?.dragHandleView(self, didDragFrom: startPoint, to: location)
	}
}
