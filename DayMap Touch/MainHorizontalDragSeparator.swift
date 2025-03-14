//
//  MainHorizontalDragSeparator.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 9/17/18.
//  Copyright © 2018 Whetstone Apps. All rights reserved.
//

import UIKit

class MainHorizontalDragSeparator: UIView {

	@IBOutlet weak var topConstraint: NSLayoutConstraint!
	private let margin: CGFloat = 200
	
	private var position: CGFloat {
		get {
			if let superview = superview, let topConstraint = topConstraint {
				return max(0.0, min(1.0, (topConstraint.constant - margin + (self.frame.size.height / 2)) / (superview.frame.size.height - 2 * margin)))
			}
			else {
				return 0.5
			}
		}
		set {
			let value = max(0.0, min(1.0, newValue))
			if let superview = superview, let topConstraint = topConstraint {
				topConstraint.constant = value * (superview.frame.size.height - 2 * margin) + margin - (self.frame.size.height / 2)
			}
		}
	}
	
	override func awakeFromNib() {
		position = ApplicationPreferences.mainSplitViewPercentageFromTop
	}
	
	override func didMoveToSuperview() {
		position = ApplicationPreferences.mainSplitViewPercentageFromTop
	}
	
	@IBAction func handlePanGesture(_ sender: UIPanGestureRecognizer) {
		guard let superview = superview else {
			return
		}
		
		let delta = sender.translation(in: self).y / (superview.frame.size.height - 2 * margin)
		
		position += delta
		ApplicationPreferences.mainSplitViewPercentageFromTop = position
		sender.setTranslation(CGPoint.zero, in: self)
	}
	
}
