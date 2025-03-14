//
//  RegularWidthMainViewController.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 9/6/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class RegularWidthMainViewController: UIViewController, CoreDataConsumer {
	
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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		loadToolbarItems(for: self)
	}
	
	// MARK: - Toolbar
	
	@IBOutlet weak var toolbar: UIToolbar!
	
	private func loadToolbarItems(for viewController: UIViewController) {
		guard let toolbar = toolbar else {
			return
		}
			
		if let provider = viewController as? DynamicToolbarItemProvider {
			provider.addToolbarItems(to: toolbar)
		}
		
		for child in viewController.children {
			loadToolbarItems(for: child)
		}
	}
}

