//
//  CompactWidthMainTabBarController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/27/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

class CompactWidthMainTabBarController: UITabBarController, CoreDataConsumer {
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			self.children.forEach { (controller) in
				if let consumer = controller as? CoreDataConsumer {
					consumer.coreDataContainer = coreDataContainer
				}
			}
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if let consumer = segue.destination as? CoreDataConsumer {
			consumer.coreDataContainer = coreDataContainer
		}
	}
}
