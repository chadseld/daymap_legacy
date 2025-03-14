//
//  MainWindowController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 10/8/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, CoreDataConsumer {

    var coreDataContainer: NSPersistentContainer? = nil {
        didSet {
            if let consumer = self.window?.contentViewController as? CoreDataConsumer {
                consumer.coreDataContainer = coreDataContainer
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let consumer = segue.destinationController as? CoreDataConsumer {
            consumer.coreDataContainer = coreDataContainer
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
