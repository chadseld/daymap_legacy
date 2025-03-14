//
//  CompactWidthProjectsListTableViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/27/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

class CompactWidthProjectsListTableViewController: UITableViewController, CoreDataConsumer, UIGestureRecognizerDelegate, ProjectTableViewCellDelegate {

	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			loadProjects()
			self.tableView.reloadData()
			
			self.children.forEach { (controller) in
				if let consumer = controller as? CoreDataConsumer {
					consumer.coreDataContainer = coreDataContainer
				}
			}

			// Notification for MOC changes
			NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: oldValue?.viewContext)
			NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChangeNotification(_:)), name: .NSManagedObjectContextObjectsDidChange,
			                                       object: coreDataContainer?.viewContext)
		}
	}
	
	// MARK: - Private
	
	@IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!
	private var sortedProjects: [Project] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
				
		self.navigationItem.leftBarButtonItem = self.editButtonItem
	}
	
	private func loadProjects() {
		guard let context = coreDataContainer?.viewContext else {
			sortedProjects = []
			return
		}
		
		if let dayMap = (try? context.fetch(DayMap.primaryFetchRequest))?.last, let projects = dayMap.projects {
			sortedProjects = projects.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [Project]
		}
		else {
			sortedProjects = []
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if let consumer = segue.destination as? CoreDataConsumer {
			consumer.coreDataContainer = coreDataContainer
		}
		
		if let consumer = segue.destination as? TaskConsumer {
			if let selectedRow = self.tableView.indexPathForSelectedRow {
				consumer.task = sortedProjects[selectedRow.row]
			}
		}
	}
	
	@IBAction func addProject(_ sender: Any) {
		guard let context = coreDataContainer?.viewContext else {
			return
		}
		
		guard let dayMap = (try? context.fetch(DayMap.primaryFetchRequest))?.last else {
			return
		}
		
		// Create a new Project
		let project = Project(context: context)
		project.sortIndex = ((sortedProjects.last?.sortIndex?.intValue ?? 0) + 1) as NSNumber
		dayMap.addToProjects(project)
		
		// Update the Table
		loadProjects()
		let insertedAtIndex = IndexPath(row: sortedProjects.count - 1, section: 0)
		self.tableView.insertRows(at: [insertedAtIndex], with: .automatic)
		self.tableView.scrollToRow(at: insertedAtIndex, at: .none, animated: true)
		
		// Edit the row title
		if let cell = self.tableView.cellForRow(at: insertedAtIndex) as? ProjectTableViewCell {
			cell.editName()
		}
	}
	
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			let before = self.sortedProjects
			self.loadProjects() // update sortedProjects
			
			self.tableView.reloadData(objectsBeforeUpdate: before, objectsAfterUpdate: self.sortedProjects, managedObjectContextObjectsDidChangeNotification: notification)
		}
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		self.tableView.endEditing(false)
		super.setEditing(editing, animated: animated)
	}
	
	// MARK: - Gestures
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer == longPressGestureRecognizer {
			return !self.isEditing
		}
		return true
	}
	
	@IBAction func longPress(_ sender: Any) {
		guard let gesture = sender as? UILongPressGestureRecognizer else {
			return
		}
		
		if case .began = gesture.state {
			if let indexPath = self.tableView.indexPathForRow(at: gesture.location(in: self.tableView)) {
				self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
				if let cell = self.tableView.cellForRow(at: indexPath) as? ProjectTableViewCell {
					cell.editName()
				}
			}
		}
	}
	
	// MARK: - TableView Delegate
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sortedProjects.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "projectCell") as! ProjectTableViewCell
		let project = sortedProjects[indexPath.row]
		cell.delegate = self
		cell.nameTextField.text = project.name ?? ""
		cell.nameTextField.isEnabled = false
		cell.projectColor = project.nativeColor ?? UIColor.white
		return cell
 	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.backgroundColor = (indexPath.row % 2) == 0 ? WSColor.tableBackground : WSColor.alternateTableBackground
	}
		
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		tableView.endEditing(false)
	}

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .delete
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if case .delete = editingStyle {
			let project = sortedProjects[indexPath.row]
			coreDataContainer?.viewContext.delete(project)
			sortedProjects.remove(at: indexPath.row)
			self.tableView.deleteRows(at: [indexPath], with: .automatic)
		}
	}

	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		let project = sortedProjects[sourceIndexPath.row]
		sortedProjects.remove(at: sourceIndexPath.row)
		sortedProjects.insert(project, at: destinationIndexPath.row)
		
		for (index, project) in sortedProjects.enumerated() {
			project.sortIndex = index as NSNumber
		}
	}
	
	// MARK: - ProjectTableViewCellDelegate
	
	func projectTableViewCellDidChangeNameText(_ cell: ProjectTableViewCell) {
		guard let row = tableView.indexPath(for: cell)?.row else {
			return
		}
		let project = sortedProjects[row]
		project.name = cell.nameTextField.text ?? "Untitled Project"
	}
}
