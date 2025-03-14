//
//  ProjectHeaderView.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/7/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

class ProjectHeaderView: NSView {

	var color: NSColor = .dayMapBlue {
		didSet {
			needsDisplay = true
		}
	}
	
	var archived: Bool = false {
		didSet {
			needsDisplay = true
		}
	}

	override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

		color.set()
		__NSRectFill(dirtyRect)
    }
}
