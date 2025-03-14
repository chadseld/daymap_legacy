//
//  CompactWidthTodayTableViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 5/9/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

class CompactWidthTodayTableViewController: UITableViewController, CoreDataConsumer, UIGestureRecognizerDelegate, TaskTableViewCellDelegate, CurrentDayConsumer {

	// MARK: - CoreDataConsumer
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			loadTasks()
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
	
	// MARK: - CurrentDayConsumer
	
	var currentDay: Date? = Date.today {
		didSet {
			loadTasks()
			self.tableView.reloadData()
		}
	}

	// MARK: - Private
	
	private var sortedTasks: [Task] = []
	@IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.navigationItem.leftBarButtonItem = self.editButtonItem
	}

	private func loadTasks() {
		guard let context = coreDataContainer?.viewContext, let currentDay = currentDay else {
			sortedTasks = []
			return
		}
		var tasks: [Task] = []
		
		// Fetch tasks scheduled for today that don't recurr
		let request: NSFetchRequest<Task> = Task.fetchRequest()
		let startDate = currentDay.quantizedToDay
		let endDate = startDate.adding(days: 1)
		request.predicate = NSPredicate(format: "(scheduledDate >= %@) AND (scheduledDate < %@) AND (recurrence == nil)", argumentArray: [startDate, endDate])
		if let result = try? context.fetch(request) {
			tasks.append(contentsOf: result)
		}
		
		// Append tasks that recurr on the date
		tasks.append(contentsOf: RecurrenceRule.tasks(recurringOn: currentDay, in: context))
		
		// Remove archived project tasks
		if ApplicationPreferences.showArchivedProjects == false {
			tasks = tasks.filter({ (task) -> Bool in
				return task.rootProject?.archived == false
			})
		}
		
		tasks = (tasks as NSArray).sortedArray(using: [SortDescriptor_SortIndexInDay, SortDescriptor_ModifiedDate]) as! [Task]
		
		sortedTasks = tasks
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if let consumer = segue.destination as? CoreDataConsumer {
			consumer.coreDataContainer = coreDataContainer
		}
		
		if let consumer = segue.destination as? TaskConsumer {
			if let selectedRow = self.tableView.indexPathForSelectedRow {
				consumer.task = sortedTasks[selectedRow.row]
			}
		}
		
		if let consumer = segue.destination as? CurrentDayConsumer {
			consumer.currentDay = currentDay
		}
	}
	
	@IBAction private func addTask(_ sender: Any) {
		guard let context = coreDataContainer?.viewContext else {
			return
		}

		guard let dayMap = (try? context.fetch(DayMap.primaryFetchRequest))?.last else {
			return
		}

		guard let inbox = dayMap.inbox else {
			return
		}
		
		let sortedInbox: [Task] = inbox.children?.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as? [Task] ?? []
		
		// Create a new Task
		let newTask = Task(context: context)
		newTask.scheduledDate = currentDay
		newTask.sortIndex = ((sortedInbox.last?.sortIndex?.intValue ?? 0) + 1) as NSNumber
		newTask.sortIndexInDay = ((sortedTasks.last?.sortIndexInDay?.intValue ?? 0) + 1) as NSNumber
		inbox.addToChildren(newTask)
		
		// Update the Table
		loadTasks()
		let insertedAtIndex = IndexPath(row: sortedTasks.count - 1, section: 0)
		self.tableView.insertRows(at: [insertedAtIndex], with: .automatic)
		self.tableView.scrollToRow(at: insertedAtIndex, at: .none, animated: true)
		
		// Edit the row title
		if let cell = self.tableView.cellForRow(at: insertedAtIndex) as? TaskTableViewCell {
			cell.editName()
		}
	}
	
	@objc func managedObjectContextDidResetNotification() {
		
	}
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			let before = self.sortedTasks
			self.loadTasks() // update sortedTasks
			
			self.tableView.reloadData(objectsBeforeUpdate: before, objectsAfterUpdate: self.sortedTasks, managedObjectContextObjectsDidChangeNotification: notification)
		}
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
				if let cell = self.tableView.cellForRow(at: indexPath) as? TaskTableViewCell {
					cell.editName()
				}
			}
		}
	}

	// MARK: - Table View Delegate
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sortedTasks.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell") as! TaskTableViewCell
		let task = sortedTasks[indexPath.row]
		cell.delegate = self
		cell.nameTextField.text = task.name ?? ""
		cell.nameTextField.isEnabled = false
		cell.completedButton.isSelected = task.completedState(at: currentDay) == .completed
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
		guard let currentDay = currentDay else {
			return
		}
		
		if case .delete = editingStyle {
			
			let subtask = sortedTasks[indexPath.row]
			
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Delete Task", style: .destructive, handler: { (action) in
				subtask.managedObjectContext?.delete(subtask)
				self.sortedTasks.remove(at: indexPath.row)
				self.tableView.deleteRows(at: [indexPath], with: .automatic)
			}))
			let unscheduleAction = UIAlertAction(title: "Remove Task from Day's Schedule", style: .default, handler: { (action) in
				let questionHandler = AlertStyleRecurrenceQuestionHandler(recurrenceDate: currentDay, parentViewController: self)
				subtask.set(scheduledDate: nil, recurrenceQuestionHandler: questionHandler) { success in
					if success {
						self.sortedTasks.remove(at: indexPath.row)
						self.tableView.deleteRows(at: [indexPath], with: .automatic)
					}
				}
			})
			alert.addAction(unscheduleAction)
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
				// do nothing
			}))
			alert.preferredAction = unscheduleAction
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		let subtask = sortedTasks[sourceIndexPath.row]
		sortedTasks.remove(at: sourceIndexPath.row)
		sortedTasks.insert(subtask, at: destinationIndexPath.row)
		
		for (index, subtask) in sortedTasks.enumerated() {
			subtask.sortIndexInDay = index as NSNumber
		}
	}
	
	// MARK: - TaskTableViewCellDelegate
	
	func taskTableViewCellDidChangeNameText(_ cell: TaskTableViewCell) {
		guard let row = tableView.indexPath(for: cell)?.row else {
			return
		}
		let task = sortedTasks[row]
		task.name = cell.nameTextField.text ?? "Untitled Task"
	}
	
	func taskTableViewCellDidToggleCompletedState(_ cell: TaskTableViewCell) {
		guard let row = tableView.indexPath(for: cell)?.row else {
			return
		}
		let task = sortedTasks[row]
		
		let questionHandler: AlertStyleRecurrenceQuestionHandler?
		if let currentDay = currentDay {
			questionHandler = AlertStyleRecurrenceQuestionHandler(recurrenceDate: currentDay, parentViewController: self)
		}
		else {
			questionHandler = nil
		}
		
		Task.toggleCompletedState(of: [task], recurrenceQuestionHandler: questionHandler) { (success) in
			cell.completedButton.isSelected = task.completedState(at: self.currentDay) == .completed
		}
	}
}
