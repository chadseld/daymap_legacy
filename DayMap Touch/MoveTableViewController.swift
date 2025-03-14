//
//  MoveTableViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/27/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

class MoveTableViewController: UITableViewController, CoreDataConsumer {
	var coreDataContainer: NSPersistentContainer? {
		didSet {
			loadSubtasks()
			self.navigationItem.title = "Projects"
			self.tableView.reloadData()
			
			self.children.forEach { (controller) in
				if let consumer = controller as? CoreDataConsumer {
					consumer.coreDataContainer = coreDataContainer
				}
			}
		}
	}
	
	var task: AbstractTask? = nil {
		didSet {
			loadSubtasks()
			self.navigationItem.title = task?.name ?? "Untitled Task"
			self.tableView.reloadData()
		}
	}
	
	// MARK: - Private
	
	var sortedSubtasks: [AbstractTask] = []

	override func viewDidLoad() {
		super.viewDidLoad()
			
		if let _ = task {
			self.navigationItem.rightBarButtonItem?.isEnabled = true
			self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem
		}
		else {
			self.navigationItem.rightBarButtonItem?.isEnabled = false
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		if let consumer = segue.destination as? CoreDataConsumer {
			consumer.coreDataContainer = coreDataContainer
		}
		
		// We don't use TaskConsumer protocol here because we don't want to set the task of our parent
		// when returning from an unwind segue
		if let moveController = segue.destination as? MoveTableViewController {
			if let selectedRow = self.tableView.indexPathForSelectedRow {
				moveController.task = sortedSubtasks[selectedRow.row]
			}
		}
	}
	
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			// Handle changes to current Task
			if let task = self.task {
				if NSManagedObjectContext.areObjectsDeletedByNotification(objects: [task], notification: notification) {
					self.performSegue(withIdentifier: "cancelSegue", sender: self)
				}
				
				if NSManagedObjectContext.areObjectsChangedByNotification(objects: [task], notification: notification) {
					self.navigationItem.title = task.name ?? "Details"
				}
			}
						
			// Handle changes to subtasks
			let before = self.sortedSubtasks
			self.loadSubtasks() // update sortedSubtasks
			self.tableView.reloadData(objectsBeforeUpdate: before, objectsAfterUpdate: self.sortedSubtasks, managedObjectContextObjectsDidChangeNotification: notification)
		}
	}

	fileprivate func loadSubtasks() {
		if let task = task {
			if let subtasks = task.children {
				sortedSubtasks = subtasks.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [AbstractTask]
			}
		}
		else if let context = coreDataContainer?.viewContext {
			if let dayMap = (try? context.fetch(DayMap.primaryFetchRequest))?.last, let projects = dayMap.projects {
				sortedSubtasks = projects.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [AbstractTask]
			}
		}
	}

	// MARK: - Table View Delegate
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sortedSubtasks.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell")!
		cell.textLabel?.text = sortedSubtasks[indexPath.row].name ?? "Untitled Task"
		return cell
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.backgroundColor = (indexPath.row % 2) == 0 ? WSColor.tableBackground : WSColor.alternateTableBackground
	}
}
