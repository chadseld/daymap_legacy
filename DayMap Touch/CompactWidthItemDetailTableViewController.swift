//
//  CompactWidthItemDetailTableViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 4/10/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

class CompactWidthItemDetailTableViewController:
	UITableViewController,
	UITextViewDelegate,
	UIGestureRecognizerDelegate,
	ColorPickerViewControllerDelegate,
	CurrentDayConsumer,
	TaskConsumer,
	TaskTableViewCellDelegate,
	CoreDataConsumer {
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			updateDetailsStack()
			loadSubtasks()
			self.navigationItem.title = task?.name ?? "Details"
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
	
	// MARK: - TaskConsumer 
	
	var task: AbstractTask? = nil {
		didSet {
			updateDetailsStack()
			loadSubtasks()
			self.navigationItem.title = task?.name ?? "Details"
			self.tableView.reloadData()
		}
	}
	
	// MARK: - CurrentDayConsumer
	
	var currentDay: Date? = Date.today {
		didSet {
			loadSubtasks()
			self.tableView.reloadData()
		}
	}
	
	// MARK: - Private
	
	@IBOutlet var detailsStackView: UIStackView!
	@IBOutlet weak var nameStackViewElement: UIView!
	@IBOutlet weak var notesStackViewElement: UIView!
	@IBOutlet weak var colorStackViewElement: UIView!
	@IBOutlet weak var scheduleStackViewElement: UIView!
	@IBOutlet weak var moveStackViewElement: UIView!
	@IBOutlet weak var completedStackViewElement: UIView!
	
	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var colorButton: UIButton!
	@IBOutlet weak var notesTextView: UITextView!
	@IBOutlet weak var scheduleButton: UIButton!
	@IBOutlet weak var completedSegmentedControl: UISegmentedControl!
	
	@IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!

	private var sortedSubtasks: [Task] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.navigationItem.rightBarButtonItem = self.editButtonItem
		
		// Notes
		notesTextView.layer.borderWidth = 0.5
		notesTextView.layer.cornerRadius = 5
		notesTextView.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
		
		colorButton.layer.cornerRadius = 7
		
		resizeDetailsStack()
		self.tableView.tableHeaderView = detailsStackView
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if let consumer = segue.destination as? CoreDataConsumer {
			consumer.coreDataContainer = coreDataContainer
		}
		
		if let consumer = segue.destination as? TaskConsumer {
			if let selectedRow = self.tableView.indexPathForSelectedRow {
				consumer.task = sortedSubtasks[selectedRow.row]
			}
			else {
				consumer.task = task
			}
		}
		
		if let consumer = segue.destination as? CurrentDayConsumer {
			consumer.currentDay = currentDay
		}
		
		if let colorPicker = segue.destination as? ColorPickerViewController {
			colorPicker.delegate = self;
			colorPicker.color = colorButton.backgroundColor ?? UIColor.black
		}
	}
		
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			// Handle changes to current Task
			if let task = self.task as? Task {
				if NSManagedObjectContext.areObjectsDeletedByNotification(objects: [task], notification: notification) {
					self.navigationController?.popViewController(animated: true)
				}
				
				if NSManagedObjectContext.areObjectsChangedByNotification(objects: ArrayByStrippingNilValues([task, task.recurrence]), notification: notification) {
					self.updateDetailsStack()
					self.navigationItem.title = task.name ?? "Details"
				}
			}
			
			// Handle changes to subtasks
			let before = self.sortedSubtasks
			self.loadSubtasks() // update sortedSubtasks
			self.tableView.reloadData(objectsBeforeUpdate: before, objectsAfterUpdate: self.sortedSubtasks, managedObjectContextObjectsDidChangeNotification: notification)
		}
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		self.tableView.endEditing(false)
		super.setEditing(editing, animated: animated)
	}

	// MARK: - Details View
	
	@IBAction func toggleNameView(_ sender: Any) {
		nameStackViewElement.isHidden = !nameStackViewElement.isHidden
		if task is Project {
			colorStackViewElement.isHidden = nameStackViewElement.isHidden
		}
		resizeDetailsStack()
	}
	
	@IBAction func toggleNotesView(_ sender: Any) {
		self.notesStackViewElement.isHidden = !self.notesStackViewElement.isHidden
		resizeDetailsStack()
	}
	
	fileprivate func updateDetailsStack() {
		if task is Task {
			nameStackViewElement.isHidden = false
			notesStackViewElement.isHidden = false
			colorStackViewElement.isHidden = true
			scheduleStackViewElement.isHidden = false
			moveStackViewElement.isHidden = false
			completedStackViewElement.isHidden = false
		}
		else if task is Project {
			nameStackViewElement.isHidden = false
			notesStackViewElement.isHidden = false
			colorStackViewElement.isHidden = false
			scheduleStackViewElement.isHidden = true
			moveStackViewElement.isHidden = true
			completedStackViewElement.isHidden = true
		}
		resizeDetailsStack()

		// Name
		nameTextField.text = task?.name ?? ""

		// Notes
		notesTextView.attributedText = task?.attributedDetailsString
		if notesTextView.attributedText.length == 0 {
			notesStackViewElement.isHidden = true
			resizeDetailsStack()
		}

		// Project Color
		if let project = task as? Project {
			colorButton.backgroundColor = project.nativeColor ?? UIColor.black
		}
		
		// Scheduled
		if let task = task as? Task, let scheduledDate = task.scheduledDate {
			let formatter = DateFormatter()
			formatter.timeZone = TimeZone(abbreviation: "GMT")!
			formatter.dateStyle = .medium
			formatter.timeStyle = .none
			
			let title: String
			if task.recurrence != nil {
				title = NSString(format: NSLocalizedString("Scheduled %@ - repeating", comment: "button title, the @ string will be a date") as NSString, formatter.string(from: scheduledDate)) as String
			}
			else {
				title = NSString(format: NSLocalizedString("Scheduled for %@", comment: "button title, the @ string will be a date") as NSString, formatter.string(from: scheduledDate)) as String
			}

			scheduleButton.setTitle(title, for: .normal)
		}
		else {
			scheduleButton.setTitle(NSLocalizedString("Tap to Schedule", comment: "button title"), for: .normal)
		}
		
		// Completed
		if let task = task as? Task {
			let completedState = task.completedState()
			switch completedState {
			case .completed:
				completedSegmentedControl.selectedSegmentIndex = 1
			case .notCompleted:
				fallthrough
			case .partiallyCompleted:
				completedSegmentedControl.selectedSegmentIndex = 0
			}
		}
	}
	
	fileprivate func resizeDetailsStack() {
		self.tableView.beginUpdates()
		UIView.animate(withDuration: 0.2) {
			var frame = self.detailsStackView.frame
			frame.size.height = self.detailsStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
			self.detailsStackView.frame = frame
		}
		self.tableView.endUpdates()
	}
	
	@IBAction func nameFieldDidEndEditing(_ sender: Any) {
		task?.name = nameTextField.text
		self.navigationItem.title = nameTextField.text
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		task?.attributedDetailsString = notesTextView.attributedText
	}
	
	func colorPicker(_ colorPicker: ColorPickerViewController, didPickColor color: UIColor) {
		if let project = task as? Project {
			colorButton.backgroundColor = color
			project.nativeColor = color
			project.modifiedDate = Date()
		}
	}
	
	@IBAction func unwindFromMoveControllerMove(_ sender: UIStoryboardSegue) {
		if let moveController = sender.source as? MoveTableViewController {
			if let taskToMove = self.task, let destinationTask = moveController.task {

				// Move the task
				taskToMove.parent?.removeFromChildren(taskToMove)
				destinationTask.addToChildren(taskToMove)

				// Since we moved ourself to a different parent, pop up to our old parent.
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	
	@IBAction func unwindFromMoveControllerCancel(_ sender: UIStoryboardSegue) {
		// Do nothing
	}
	
	@IBAction func unwindFromScheduleControllerSchedule(_ sender: UIStoryboardSegue) {
		updateDetailsStack()
	}
	
	@IBAction func changeCompletedState(_ sender: Any) {
		if let task = task as? Task {
			let completedState: TaskCompletedState
			if completedSegmentedControl.selectedSegmentIndex == 0 {
				completedState = .notCompleted
				
			}
			else {
				completedState = .completed
			}
			
			let questionHandler: AlertStyleRecurrenceQuestionHandler?
			if let currentDay = currentDay {
				questionHandler = AlertStyleRecurrenceQuestionHandler(recurrenceDate: currentDay, parentViewController: self)
			}
			else {
				questionHandler = nil
			}
			task.set(completedState: completedState, recurrenceQuestionHandler: questionHandler, completion: nil)
		}
	}
	
	@IBAction func createSubtask(_ sender: Any) {
		guard let task = task, let context = task.managedObjectContext else {
			return
		}
		
		// Create a new Task
		let newTask = Task(context: context)
		newTask.sortIndex = ((sortedSubtasks.last?.sortIndex?.intValue ?? 0) + 1) as NSNumber
		task.addToChildren(newTask)
		
		// Update the Table
		loadSubtasks()
		let insertedAtIndex = IndexPath(row: sortedSubtasks.count - 1, section: 0)
		self.tableView.insertRows(at: [insertedAtIndex], with: .automatic)
		self.tableView.scrollToRow(at: insertedAtIndex, at: .none, animated: true)
		
		// Edit the row title
		if let cell = self.tableView.cellForRow(at: insertedAtIndex) as? TaskTableViewCell {
			cell.editName()
		}
	}
	
	// MARK: - Subtasks
	
	fileprivate func loadSubtasks() {
		guard let task = task else {
			sortedSubtasks = []
			return
		}
		
		if let subtasks = task.children {
			sortedSubtasks = subtasks.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [Task]
		}
		else {
			sortedSubtasks = []
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
		return sortedSubtasks.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell") as! TaskTableViewCell
		let task = sortedSubtasks[indexPath.row]
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
		if case .delete = editingStyle {
			let subtask = sortedSubtasks[indexPath.row]
			subtask.managedObjectContext?.delete(subtask)
			sortedSubtasks.remove(at: indexPath.row)
			self.tableView.deleteRows(at: [indexPath], with: .automatic)
		}
	}

	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		let subtask = sortedSubtasks[sourceIndexPath.row]
		sortedSubtasks.remove(at: sourceIndexPath.row)
		sortedSubtasks.insert(subtask, at: destinationIndexPath.row)
		
		for (index, subtask) in sortedSubtasks.enumerated() {
			subtask.sortIndex = index as NSNumber
		}
	}
	
	// MARK: - TaskTableViewCellDelegate
	
	func taskTableViewCellDidChangeNameText(_ cell: TaskTableViewCell) {
		guard let row = tableView.indexPath(for: cell)?.row else {
			return
		}
		let task = sortedSubtasks[row]
		task.name = cell.nameTextField.text ?? "Untitled Task"
	}
	
	func taskTableViewCellDidToggleCompletedState(_ cell: TaskTableViewCell) {
		guard let row = tableView.indexPath(for: cell)?.row else {
			return
		}
		let task = sortedSubtasks[row]

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
