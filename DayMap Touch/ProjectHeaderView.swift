//
//  ProjectHeaderView.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 11/14/18.
//  Copyright © 2018 Whetstone Apps. All rights reserved.
//

import UIKit

class ProjectHeaderView: UIView {
	
	@IBOutlet weak var nameLabel: UILabel!

	var color: UIColor = .dayMapBlue {
		didSet {
			setNeedsDisplay()
		}
	}
	
	var archived: Bool = false {
		didSet {
			setNeedsDisplay()
		}
	}
	
	override func draw(_ rect: CGRect) {
		super.draw(rect)
		
		color.set()
		UIRectFill(rect)
	}
}
