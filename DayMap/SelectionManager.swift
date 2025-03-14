//
//  SelectionManager.swift
//  DayMap
//
//  Created by Chad Seldomridge on 1/2/18.
//  Copyright © 2018 Whetstone Apps. All rights reserved.
//

import Cocoa

extension Notification.Name {
	static let SelectionManagerDidChangeSelection = Notification.Name("SelectionManagerDidChangeSelection")
}

class SelectionManager: NSObject {
	static let shared = SelectionManager()
	
	private(set) var selection: [String] = []
	
	func clearSelection(sender: Any) {
		selection = []
		sendNotification(sender: sender)
	}
	
	func select(project: Project, sender: Any) {
		selection = [project.uuid!]
		sendNotification(sender: sender)
	}
	
	func select(tasks: [Task], sender: Any) {
		selection = tasks.map { $0.uuid! }
		sendNotification(sender: sender)
	}
	
	private func sendNotification(sender: Any) {
		NotificationCenter.default.post(name: .SelectionManagerDidChangeSelection, object: self, userInfo: ["sender" : sender])
	}
}
