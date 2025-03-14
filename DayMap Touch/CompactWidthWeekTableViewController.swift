
//
//  CompactWidthWeekTableViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 5/16/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

class CompactWidthWeekTableViewController: UITableViewController, CoreDataConsumer, UIGestureRecognizerDelegate, TaskTableViewCellDelegate, CurrentDayConsumer, CustomRootNavigationViewController {

	// MARK: - CoreDataConsumer
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
            gracefulReloadSortedDaysAndTableView()
			
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
	
	var currentDay: Date? = nil {
		didSet {
			if oldValue != currentDay {
				guard let context = coreDataContainer?.viewContext, let currentDay = currentDay else {
					sortedDays = []
					tableView.reloadData()
					return
				}
				
				// We have not loaded anything yet
				guard let earliestDay = sortedDays.first?.day, let latestDay = sortedDays.last?.day else {
					sortedDays = tasksInRange(startDate: currentDay.adding(days: -marginDaysToLoad), endDate: currentDay.adding(days: marginDaysToLoad))
					tableView.reloadData()
					tableView.scrollToRow(at: IndexPath(row: 0, section: marginDaysToLoad), at: .top, animated: false)
					
					return
				}
				
				// We need to load earlier days
				if earliestDay.isLaterThan(currentDay.adding(days: -minimumMarginOfDaysToLoad)) {
					log_debug("Need to load earlier days")
					
					var dayToLoad = earliestDay.adding(days: -1)
					var numberOfSectionsAdded = 0
					while dayToLoad.isLaterThanOrEqualTo(currentDay.adding(days: -marginDaysToLoad)) {
						let tasks = fetchTasks(for: dayToLoad, in: context)
						sortedDays.insert(Day(day: dayToLoad, tasks: tasks), at: 0)
						numberOfSectionsAdded += 1
						dayToLoad = dayToLoad.adding(days: -1)
					}
					
					tableView.reloadData()
					var newContentHeight: CGFloat = 0
					for i in 0..<numberOfSectionsAdded {
						newContentHeight += tableView.rect(forSection: i).height
					}
					tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + newContentHeight), animated: false)
				}
				
				// We need to load later days
				if latestDay.isEarlierThan(currentDay.adding(days: minimumMarginOfDaysToLoad)) {
					log_debug("Need to load later days")
					tableView.beginUpdates()
					var dayToLoad = latestDay.adding(days: 1)
					var numberOfSectionsAdded = 0
					while dayToLoad.isEarlierThanOrEqualTo(currentDay.adding(days: marginDaysToLoad)) {
						let tasks = fetchTasks(for: dayToLoad, in: context)
						sortedDays.append(Day(day: dayToLoad, tasks: tasks))
						numberOfSectionsAdded += 1
						dayToLoad = dayToLoad.adding(days: 1)
					}
					
					tableView.insertSections(IndexSet(integersIn: sortedDays.count - numberOfSectionsAdded..<sortedDays.count), with: .none)
					tableView.endUpdates()
				}
				
				log_debug("Loaded range is \(sortedDays.first!.day) through \(sortedDays.last!.day)")
			}
		}
	}
	
	// MARK: - Private
	
	private struct Day: TableSectionObject { // TODO make TableSectionObject hashable, and implement hash here instead of in MOC did change
		var day: Date
		var tasks: [Task]?
		
		var sectionValue: Any {
			return day
		}
		
		var children: [Any]? {
			return tasks
		}
	}

	private var sortedDays: [Day] = []
	private var scrollingManually = true
	@IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView.showsVerticalScrollIndicator = false
		
		self.navigationItem.leftBarButtonItem = self.editButtonItem
		
		currentDay = .today
	}

	private let maximumMarginOfDaysToLoadBeforeTrimming = 16 * 7
    private let marginDaysToLoad = 8 * 7
	private let minimumMarginOfDaysToLoad = 4 * 7
	
//    private func trimSortedDays() {
//        // We have not loaded anything yet
//        guard let currentDay = currentDay, var earliestDay = sortedDays.first?.day, var latestDay = sortedDays.last?.day else {
//            return
//        }
//
//        // Need to trim earliest days
//        if earliestDay.isEarlierThan(currentDay.adding(days: -maximumMarginOfDaysToLoadBeforeTrimming)) {
//            log_debug("Need to trim earliest days")
//
//            var numSectionsRemoved = 0
//            var removedContentHeight: CGFloat = 0
//            while earliestDay.isEarlierThanOrEqualTo(currentDay.adding(days: -marginDaysToLoad)) {
//                log_debug("Removing \(String(describing: sortedDays.first?.day))")
//                removedContentHeight += tableView.rect(forSection: numSectionsRemoved).height
//                log_debug("removedContentHeight = \(removedContentHeight)")
//                numSectionsRemoved += 1
//                earliestDay = earliestDay.adding(days: 1)
//            }
//
//            sortedDays.removeFirst(numSectionsRemoved)
//            tableView.reloadData()
//            tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y - removedContentHeight), animated: false)
//        }
//
//        // Need to trim latest days
//        if latestDay.isLaterThan(currentDay.adding(days: maximumMarginOfDaysToLoadBeforeTrimming)) {
//            log_debug("Need to trim latest days")
//            while latestDay.isLaterThanOrEqualTo(currentDay.adding(days: marginDaysToLoad)) {
//                log_debug("Removing \(String(describing: sortedDays.last?.day))")
//                sortedDays.removeLast()
//                latestDay = latestDay.adding(days: 1)
//            }
//        }
//    }
	
	private func gracefulReloadSortedDaysAndTableView(additionalUpdatedIDs: Set<NSManagedObjectID> = Set<NSManagedObjectID>()) {
		guard let currentDay = currentDay else {
			sortedDays = []
			tableView.reloadData()
			return
		}

		let before = sortedDays
		sortedDays = tasksInRange(startDate: currentDay.adding(days: -marginDaysToLoad), endDate: currentDay.adding(days: marginDaysToLoad))
		
		let hasher: (Any) -> String = { obj in
			if let day = obj as? Day {
				return "\(day.day.timeIntervalSinceReferenceDate)_day"
			}
			else if let task = obj as? Task {
				return task.objectID.uriRepresentation().absoluteString
			}
			else {
				return "" // Should never get here
			}
		}
		
		// Figure out indexes from additionalUpdatedIDs
		var updatedTaskIndexes: [IndexPath] = []
		for (section, day) in sortedDays.enumerated() {
			for (row, task) in day.tasks?.enumerated() ?? [].enumerated() {
				if additionalUpdatedIDs.contains(task.objectID) {
					updatedTaskIndexes.append(IndexPath(row: row, section: section))
				}
			}
		}
		
		tableView.reloadData(sectionObjectsBeforeUpdate: before, sectionObjectsAfterUpdate: sortedDays, objectHash: hasher, additionalIndexesUpdated: updatedTaskIndexes)
	}
	
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        DispatchQueue.main.async {
            if let firstVisibleSection = self.tableView.indexPathsForVisibleRows?.first?.section {
                self.currentDay = self.sortedDays[firstVisibleSection + 1].day
//                self.trimSortedDays()
            }
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        DispatchQueue.main.async {
            if let firstVisibleSection = self.tableView.indexPathsForVisibleRows?.first?.section {
                self.currentDay = self.sortedDays[firstVisibleSection + 1].day
            }
        }
    }
    
    private func tasksInRange(startDate: Date,  endDate: Date) -> [Day] {
		guard let context = coreDataContainer?.viewContext else {
			return []
		}
        
        var sortedResult: [Day] = []
        
		var dayToLoad = startDate
		while dayToLoad.isEarlierThanOrEqualTo(endDate) {
			let tasks = fetchTasks(for: dayToLoad, in: context)
			sortedResult.append(Day(day: dayToLoad, tasks: tasks))
			
			dayToLoad = dayToLoad.adding(days: 1)
		}
        
        return sortedResult
	}
	
	private func fetchTasks(for day: Date, in context: NSManagedObjectContext) -> [Task]? {
		var tasks: [Task] = []
		
		// Fetch tasks scheduled for today that don't recurr
		let request: NSFetchRequest<Task> = Task.fetchRequest()
		let startDate = day.quantizedToDay
		let endDate = startDate.adding(days: 1)
		request.predicate = NSPredicate(format: "(scheduledDate >= %@) AND (scheduledDate < %@) AND (recurrence == nil)", argumentArray: [startDate, endDate])
		if let result = try? context.fetch(request) {
			tasks.append(contentsOf: result)
		}
		
		// Append tasks that recurr on the date
		tasks.append(contentsOf: RecurrenceRule.tasks(recurringOn: day, in: context))
		
		// Remove archived project tasks
		if ApplicationPreferences.showArchivedProjects == false {
			tasks = tasks.filter({ (task) -> Bool in
				return task.rootProject?.archived == false
			})
		}
		
		tasks = (tasks as NSArray).sortedArray(using: [SortDescriptor_SortIndexInDay, SortDescriptor_ModifiedDate]) as! [Task]
		
		return tasks.count > 0 ? tasks : nil
	}
    
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			
			// TODO: - also look for changes to task recurrence, and add the affected tasks here
			
			let updatedIDs = NSManagedObjectContext.objectIDsUpdatedRefreshedOrInvalidatedByNotification(notification)
			self.gracefulReloadSortedDaysAndTableView(additionalUpdatedIDs: updatedIDs)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if let consumer = segue.destination as? CoreDataConsumer {
			consumer.coreDataContainer = coreDataContainer
		}
		
		if let consumer = segue.destination as? TaskConsumer {
			if let selectedRow = self.tableView.indexPathForSelectedRow, let task = sortedDays[selectedRow.section].tasks?[selectedRow.row] {
				consumer.task = task
			}
		}
		
		if let consumer = segue.destination as? CurrentDayConsumer {
			consumer.currentDay = currentDay
		}
	}
	
	@IBAction private func addTask(_ sender: Any) {
		guard var firstVisibleSection = self.tableView.indexPathsForVisibleRows?.first?.section else {
			return
		}
		firstVisibleSection += 1
		
		addTask(in: firstVisibleSection)
	}
	
	private func addTask(in section: Int) {
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
		newTask.scheduledDate = sortedDays[section].day
		newTask.sortIndex = ((sortedInbox.last?.sortIndex?.intValue ?? 0) + 1) as NSNumber
		newTask.sortIndexInDay = ((sortedDays[section].tasks?.last?.sortIndexInDay?.intValue ?? 0) + 1) as NSNumber
		inbox.addToChildren(newTask)
	
		// Update the Table
		tableView.beginUpdates()
		sortedDays[section].tasks = fetchTasks(for: sortedDays[section].day, in: context)
		let insertedAtIndex = IndexPath(row: (sortedDays[section].tasks?.count ?? 1) - 1, section: section)
		if sortedDays[section].tasks?.count == 1 { // previously had zero tasks, and were therefore showing the "emptyDayCell"
			tableView.deleteRows(at: [insertedAtIndex], with: .automatic)
		}
		self.tableView.insertRows(at: [insertedAtIndex], with: .automatic)
		tableView.endUpdates()
		self.tableView.scrollToRow(at: insertedAtIndex, at: .none, animated: true)
	
		// Edit the row title
		if let cell = self.tableView.cellForRow(at: insertedAtIndex) as? TaskTableViewCell {
			cell.editName()
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
		return sortedDays.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let tasks = sortedDays[section].tasks {
			return tasks.count
		}
		else {
			return 1
		}
	}
	
	private let dayHeaderDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeZone = TimeZone(abbreviation: "GMT")!
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter
	}()
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return dayHeaderDateFormatter.string(from: sortedDays[section].day)
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let tasks = sortedDays[indexPath.section].tasks {
			let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell") as! TaskTableViewCell
			let task = tasks[indexPath.row]
			cell.delegate = self
			cell.nameTextField.text = task.name ?? ""
			cell.nameTextField.isEnabled = false
			cell.completedButton.isSelected = task.completedState(at: sortedDays[indexPath.section].day) == .completed
			return cell
		}
		else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "emptyDayCell")!
			return cell
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if sortedDays[indexPath.section].tasks == nil {
			addTask(in: indexPath.section)
		}
	}
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		tableView.endEditing(false)
	}

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		if let _ = sortedDays[indexPath.section].tasks {
			return .delete
		}
		return .none
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if case .delete = editingStyle, let tasks = sortedDays[indexPath.section].tasks {
			let subtask = tasks[indexPath.row]
			
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Delete Task", style: .destructive, handler: { (action) in
				subtask.managedObjectContext?.delete(subtask)
				self.gracefulReloadSortedDaysAndTableView()
			}))
			let unscheduleAction = UIAlertAction(title: "Remove Task from Day's Schedule", style: .default, handler: { (action) in
				let questionHandler = AlertStyleRecurrenceQuestionHandler(recurrenceDate: self.sortedDays[indexPath.section].day, parentViewController: self)				
				subtask.set(scheduledDate: nil, recurrenceQuestionHandler: questionHandler) { success in
					if success {
						self.gracefulReloadSortedDaysAndTableView()
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
		if let _ = sortedDays[indexPath.section].tasks {
			return true
		}
		return false
	}
	
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		guard let subtask = sortedDays[sourceIndexPath.section].tasks?[sourceIndexPath.row] else {
			tableView.reloadData()
			return
		}
		
		sortedDays[sourceIndexPath.section].tasks?.remove(at: sourceIndexPath.row)
		if (sortedDays[sourceIndexPath.section].tasks?.count == 0) {
			sortedDays[sourceIndexPath.section].tasks = nil
		}
		
		if sortedDays[destinationIndexPath.section].tasks == nil {
			sortedDays[destinationIndexPath.section].tasks = [subtask]
		}
		else {
			sortedDays[destinationIndexPath.section].tasks?.insert(subtask, at: destinationIndexPath.row)
		}
		
		subtask.scheduledDate = sortedDays[destinationIndexPath.section].day
		
		for (index, subtask) in sortedDays[destinationIndexPath.section].tasks!.enumerated() {
			subtask.sortIndexInDay = index as NSNumber
		}
	}
	
	// MARK: - TaskTableViewCellDelegate
	
	func taskTableViewCellDidChangeNameText(_ cell: TaskTableViewCell) {
		guard let indexPath = tableView.indexPath(for: cell) else {
			return
		}
		
		if let task =  sortedDays[indexPath.section].tasks?[indexPath.row] {
			task.name = cell.nameTextField.text ?? "Untitled Task"
		}
	}
	
	func taskTableViewCellDidToggleCompletedState(_ cell: TaskTableViewCell) {
		guard let indexPath = tableView.indexPath(for: cell) else {
			return
		}
		if let task =  sortedDays[indexPath.section].tasks?[indexPath.row] {
			let questionHandler = AlertStyleRecurrenceQuestionHandler(recurrenceDate: sortedDays[indexPath.section].day, parentViewController: self)
			Task.toggleCompletedState(of: [task], recurrenceQuestionHandler: questionHandler) { (success) in
				cell.completedButton.isSelected = task.completedState(at: self.sortedDays[indexPath.section].day) == .completed
			}
		}
	}
    
    // MARK: - CustomRootNavigationViewController
    
    func navigateToRoot() {
        if currentDay != .today {
			self.sortedDays = []
            currentDay = .today
        }
    }
}
