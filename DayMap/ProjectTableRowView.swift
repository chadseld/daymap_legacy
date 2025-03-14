//
//  ProjectTableRowView.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/24/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

class ProjectTableRowView: NSTableRowView {
	
	override var isOpaque: Bool {
		return true
	}
	
	override func drawSelection(in dirtyRect: NSRect) {
		if isSelected && selectionHighlightStyle == .regular {
			if isEmphasized {
				NSColor.selectedControlColor.set()
			}
			else {
				NSColor.secondarySelectedControlColor.set()
			}
			__NSRectFillUsingOperation(dirtyRect, .copy)
		}
		else {
			super.drawSelection(in: dirtyRect)
		}
	}
}
