//
//  DMEndlessScrollingViewItem.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/31/15.
//  Copyright (c) 2015 Whetstone Apps. All rights reserved.
//

import Cocoa

class DMEndlessScrollingViewItem: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		let testView = WSTestRectView(frame: NSMakeRect(0, 0, 200, 200))
		self.view = testView
    }
    
}
