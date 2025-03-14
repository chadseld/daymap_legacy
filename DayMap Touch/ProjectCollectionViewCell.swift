//
//  ProjectCollectionViewCell.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 11/14/18.
//  Copyright © 2018 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

class ProjectCollectionViewCell: UICollectionViewCell, UITableViewDelegate, OutlineViewConverterDataSource, CoreDataConsumer {
		
	// MARK: - CoreDataConsumer
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			outlineViewConverter.reloadData(for: tableView)
			
//			self.children.forEach { (controller) in
//				if let consumer = controller as? CoreDataConsumer {
//					consumer.coreDataContainer = coreDataContainer
//				}
//			}
			
			// Notification for MOC changes
			NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: oldValue?.viewContext)
			NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChangeNotification(_:)), name: .NSManagedObjectContextObjectsDidChange,
												   object: coreDataContainer?.viewContext)
		}
	}

	@objc dynamic var project: Project? {
		didSet {
			outlineViewConverter.reloadData(for: tableView)
			headerView?.color = project?.nativeColor ?? .dayMapBlue
			headerView?.nameLabel.text = project?.name ?? ""
			
			// Notification for MOC changes
			NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: oldValue?.managedObjectContext)
			NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChangeNotification(_:)), name: .NSManagedObjectContextObjectsDidChange,
												   object: project?.managedObjectContext)
		}
	}
		
	// MARK: - Private
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView?.dataSource = outlineViewConverter
		}
	}
	@IBOutlet weak var headerView: ProjectHeaderView!
	
//	override func viewDidLoad() {
//		super.viewDidLoad()
//
//
//		NotificationCenter.default.addObserver(self, selector: #selector(selectionManagerDidChangeSelectionNotification(_:)), name: .SelectionManagerDidChangeSelection, object: nil)
//	}
	
//	@objc func selectionManagerDidChangeSelectionNotification(_ notification: Notification) {
//		guard let sender = notification.userInfo?["sender"] as AnyObject?, sender !== self else { // ignore notifications that originate from us
//			return
//		}
//
//		// TODO: - Update selection
//	}
	
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			// TODO: - this
		}
	}
	
	// MARK: - OutlineViewConverterDataSource
	
	private lazy var outlineViewConverter: OutlineViewConverter = {
		let converter = OutlineViewConverter()
		converter.dataSource = self
		return converter
	}()
	
	func outlineViewConverter(_ outlineView: OutlineViewConverter, numberOfChildrenOfItem item: Any?) -> Int {
		if item == nil {
			return project?.children?.count ?? 0
		}
		
		if let task = item as? AbstractTask {
			return task.children?.count ?? 0
		}
		
		return 0
	}
	
	func outlineViewConverter(_ outlineView: OutlineViewConverter, child index: Int, ofItem item: Any?) -> Any {
		if item == nil {
			return (project!.children!.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [Task])[index]
		}
		
		if let task = item as? AbstractTask {
			return (task.children!.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [Task])[index]
		}
			
		return "Error"
	}
	
//	func outlineViewConverter(_ outlineView: OutlineViewConverter, objectValueItem item: Any?) -> Any? {
//		return item
//	}
	
	func outlineViewConverter(_ outlineView: OutlineViewConverter, viewFor item: Any, indentation: Int) -> UITableViewCell? {
		let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell") as! ProjectTableTaskCellView
		
		if let task = item as? Task {
			cell.nameLabel.text = task.name
			cell.detailsLabel.attributedText = task.attributedDetailsString
			// scheduled icon, completed etc...
			// shows disclosure triangle
			// indentation
				// or should the disclosure triangle and indentation be entierly handled by the OutlineViewConverter?
		}
		
		//		let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell") as! ProjectTableTaskCellView
		////		let task = sortedTasks[indexPath.row]
		////		cell.delegate = self
		////		cell.nameTextField.text = task.name ?? ""
		////		cell.nameTextField.isEnabled = false
		////		cell.completedButton.isSelected = task.completedState() == .completed
		//		cell.nameLabel.text = "test"
		//		return cell

		return cell
	}

	// MARK: - Table View Delegate
		
	
//	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//		cell.backgroundColor = (indexPath.row % 2) == 0 ? WSColor.tableBackground : WSColor.alternateTableBackground
//	}
	
//	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//		tableView.endEditing(false)
//	}
	
//	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
//		return .delete
//	}
	
//	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//		if case .delete = editingStyle {
//			// TODO: ask if this occurrence or all occurrences
//			let subtask = sortedTasks[indexPath.row]
//			subtask.managedObjectContext?.delete(subtask)
//			sortedTasks.remove(at: indexPath.row)
//			self.tableView.deleteRows(at: [indexPath], with: .automatic)
//		}
//	}
//
//	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//		return true
//	}
//
//	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//		let subtask = sortedTasks[sourceIndexPath.row]
//		sortedTasks.remove(at: sourceIndexPath.row)
//		sortedTasks.insert(subtask, at: destinationIndexPath.row)
//
//		for (index, subtask) in sortedTasks.enumerated() {
//			subtask.sortIndexInDay = index as NSNumber
//		}
//	}
}
