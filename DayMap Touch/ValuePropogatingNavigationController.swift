//
//  ValuePropogatingNavigationController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/27/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

protocol CustomRootNavigationViewController {
    func navigateToRoot()
}

class ValuePropogatingNavigationController: UINavigationController, CoreDataConsumer, TaskConsumer {
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			self.children.forEach { (controller) in
				if let consumer = controller as? CoreDataConsumer {
					consumer.coreDataContainer = coreDataContainer
				}
			}
		}
	}
	
	var task: AbstractTask? = nil {
		didSet {
			self.children.forEach { (controller) in
				if let consumer = controller as? TaskConsumer {
					consumer.task = task
				}
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if let consumer = segue.destination as? CoreDataConsumer {
			consumer.coreDataContainer = coreDataContainer
		}
		
		if let consumer = segue.destination as? TaskConsumer {
			consumer.task = task
		}
	}
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let top = self.topViewController
        
        let result = super.popToRootViewController(animated: animated)
        
        // If the top view was unchanged, and wants custom root navigation
        if let root = self.topViewController as? CustomRootNavigationViewController, top == self.topViewController {
            root.navigateToRoot()
        }
        
        return result
    }
}
