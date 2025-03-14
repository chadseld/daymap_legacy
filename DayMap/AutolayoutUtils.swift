//
//  AutolayoutUtils.swift
//  DayMap
//
//  Created by Chad Seldomridge on 1/2/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
#else
#endif

#if os(iOS)
	
extension NSLayoutConstraint {
	class func constraintsFillingSuperview(view: UIView) -> [NSLayoutConstraint] {
		let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view" : view])
		let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view" : view])
		return horizontalConstraints + verticalConstraints
	}
}

#endif
