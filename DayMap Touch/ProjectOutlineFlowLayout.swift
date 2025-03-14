//
//  ProjectOutlineFlowLayout.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 3/6/19.
//  Copyright © 2019 Whetstone Apps. All rights reserved.
//

import UIKit

class ProjectOutlineFlowLayout: UICollectionViewFlowLayout {
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		return true
	}
	
	override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
		let context = super.invalidationContext(forBoundsChange: newBounds)
		if let context = context as? UICollectionViewFlowLayoutInvalidationContext {
			context.invalidateFlowLayoutDelegateMetrics = true
		}
		return context
	}
}
