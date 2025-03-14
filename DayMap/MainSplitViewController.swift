//
//  MainSplitViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 10/8/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController, CoreDataConsumer {

    var coreDataContainer: NSPersistentContainer? = nil {
        didSet {
            self.children.forEach { (controller) in
                if let consumer = controller as? CoreDataConsumer {
                    consumer.coreDataContainer = coreDataContainer
                }
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let consumer = segue.destinationController as? CoreDataConsumer {
            consumer.coreDataContainer = coreDataContainer
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
