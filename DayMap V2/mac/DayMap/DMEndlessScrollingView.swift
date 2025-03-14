//
//  DMEndlessScrollingView.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/31/15.
//  Copyright (c) 2015 Whetstone Apps. All rights reserved.
//

import Cocoa

enum DMEndlessScrollingViewAxis {
	case Horizontal, Vertical
}

class DMEndlessScrollingView: NSView {

	var scrollAxis: DMEndlessScrollingViewAxis = .Horizontal
	var layoutDelegate: DMEndlessSCrollingViewLayoutDelegate?
	var dataSource: DMEndlessSCrollingViewDataSource?
	var uiDelegate: DMEndlessSCrollingViewUIDelegate?
	
	init(frame frameRect: NSRect, scrollAxis axis: DMEndlessScrollingViewAxis) {
		super.init(frame: frameRect)
		self.privateInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.privateInit()
	}
	
	func privateInit() {
		
	}
}

protocol DMEndlessSCrollingViewLayoutDelegate : NSObjectProtocol {
	
	//	optional func numberOfRowsInTableView(tableView: NSTableView) -> Int
	
}

protocol DMEndlessSCrollingViewDataSource : NSObjectProtocol {
}

protocol DMEndlessSCrollingViewUIDelegate : NSObjectProtocol {
}

