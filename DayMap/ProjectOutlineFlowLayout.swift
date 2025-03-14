//
//  ProjectOutlineFlowLayout.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/6/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

class ProjectOutlineFlowLayout: NSCollectionViewFlowLayout {
	override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
		invalidateLayout()
		return true
	}
}
