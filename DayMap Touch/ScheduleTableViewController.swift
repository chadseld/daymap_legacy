//
//  ScheduleTableViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 4/30/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

class ScheduleTableViewController: UITableViewController, TaskConsumer, RecurrenceFrequencyTableViewControllerDelegate, RecurrenceEndingTableViewControllerDelegate {
	
	var task: AbstractTask? = nil {
		didSet {
			// By default, immediately schedule the task if it is not already scheduled
			if let task = task as? Task {
				if task.scheduledDate == nil {
					task.scheduledDate = Date.today
					updateSortIndexInDay()
				}
			}
			
			if self.isViewLoaded {
				updateControls()
			}
		}
	}
	
	// MARK: - Private
	
	// Cells
	var oneTimeCells: [UITableViewCell]?
	var recurringCells: [UITableViewCell]?
	@IBOutlet weak var datePicker: UIDatePicker!
	@IBOutlet weak var scheduledSwitch: UISwitch!
	@IBOutlet weak var recurringSegmentedControl: UISegmentedControl!
	@IBOutlet weak var repeatEveryLabel: UILabel!
	@IBOutlet weak var endAfterLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		datePicker.timeZone = TimeZone(abbreviation: "GMT")!
		
		var staticCells: [UITableViewCell] = []
		for row in 0 ..< self.tableView.numberOfRows(inSection: 0) {
			staticCells.append(self.tableView.cellForRow(at: IndexPath(row: row, section: 0))!)
		}
		
		oneTimeCells = staticCells.filter({ (cell) -> Bool in
			return cell.reuseIdentifier!.hasPrefix("schedule")
		})
		
		recurringCells = staticCells

		updateControls()
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		if let consumer = segue.destination as? TaskConsumer {
			consumer.task = task
		}
		
		if let controller = segue.destination as? RecurrenceFrequencyTableViewController {
			if let task = task as? Task, let recurrence = task.recurrence {
				controller.frequency = recurrence.recurrenceFrequency ?? .daily
			}
			controller.delegate = self
		}
		
		if let controller = segue.destination as? RecurrenceEndingTableViewController {
			if let task = task as? Task, let recurrence = task.recurrence {
				controller.endAfterDate = recurrence.endAfterDate
				controller.endAfterCount = recurrence.endAfterCount?.intValue
			}
			controller.delegate = self
		}
	}
	
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			// Handle changes to current Task
			if let task = self.task {
				if NSManagedObjectContext.areObjectsDeletedByNotification(objects: [task], notification: notification) {
					self.performSegue(withIdentifier: "cancelSegue", sender: self)
				}
			}
		}
	}

	private func updateControls() {
		guard let task = task as? Task else {
			scheduledSwitch.isOn = false
			recurringSegmentedControl.selectedSegmentIndex = 0
			return
		}
		
		if let scheduledDate = task.scheduledDate {
			scheduledSwitch.isOn = true
			datePicker.date = scheduledDate
			datePicker.isEnabled = true
			recurringSegmentedControl.selectedSegmentIndex = (task.recurrence == nil) ? 0 : 1
			recurringSegmentedControl.isEnabled = true
		}
		else {
			scheduledSwitch.isOn = false
			datePicker.date = Date.today
			datePicker.isEnabled = false
			recurringSegmentedControl.selectedSegmentIndex = 0
			recurringSegmentedControl.isEnabled = false
		}
		
		if let recurrence = task.recurrence {
			repeatEveryLabel.text = recurrence.recurrenceFrequency?.stringValue
			if let endAfterDate = recurrence.endAfterDate {
				let formatter = DateFormatter()
				formatter.timeZone = TimeZone(abbreviation: "GMT")!
				formatter.dateStyle = .medium
				formatter.timeStyle = .none

				endAfterLabel.text = formatter.string(from: endAfterDate)
			}
			else if let endAfterCount = recurrence.endAfterCount {
				endAfterLabel.text = NSString(format: NSLocalizedString("%d times", comment: "Recurring task ends after n times.") as NSString, endAfterCount.intValue) as String
			}
			else {
				endAfterLabel.text = NSLocalizedString("Never", comment: "Recurring task that never ends.")
			}
		}
		
		self.tableView.reloadData()
	}

	@IBAction func scheduledSwitchTapped(_ sender: Any) {
		guard let task = task as? Task else {
			return
		}
		
		if scheduledSwitch.isOn {
			task.scheduledDate = datePicker.date.quantizedToDay
			updateSortIndexInDay()
		}
		else {
			task.scheduledDate = nil
			task.sortIndexInDay = -1
			task.recurrence = nil
		}
		updateControls()
	}
	
	@IBAction func dateChanged(_ sender: Any) {
		guard let task = task as? Task else {
			return
		}
		
		task.scheduledDate = datePicker.date.quantizedToDay
		updateSortIndexInDay()
	}
	
	@IBAction func recurringSegmentedControlTapped(_ sender: Any) {
		if let task = task as? Task, let context = task.managedObjectContext {
			if recurringSegmentedControl.selectedSegmentIndex == 1 {
				if task.recurrence == nil {
					task.recurrence = RecurrenceRule(context: context)
				}
			}
			else {
				task.recurrence = nil
			}
		}
		updateControls()
		self.tableView.reloadData()
	}
	
	func updateSortIndexInDay() {
		if let task = task as? Task, let scheduledDate = task.scheduledDate, let context = task.managedObjectContext {
			let request: NSFetchRequest<Task> = Task.fetchRequest()
			let startDate = scheduledDate.quantizedToDay
			let endDate = startDate.adding(days: 1)
			request.predicate = NSPredicate(format: "(scheduledDate >= %@) AND (scheduledDate < %@) AND (recurrence == nil)", argumentArray: [startDate, endDate])
			if let result = try? context.fetch(request) {
				let sortedTasks = (result as NSArray).sortedArray(using: [SortDescriptor_SortIndexInDay, SortDescriptor_ModifiedDate]) as! [Task]
				task.sortIndexInDay = ((sortedTasks.last?.sortIndexInDay?.intValue ?? 0) + 1) as NSNumber
			}
		}
	}
	
	// MARK: - RecurrenceFrequencyTableViewControllerDelegate
	
	func recurrenceFrequencyTableViewControllerDidChangeFrequency(_ controller: RecurrenceFrequencyTableViewController, frequency: RecurrenceFrequency) {
		if let task = task as? Task, let recurrence = task.recurrence {
			recurrence.recurrenceFrequency = frequency
		}
		updateControls()
	}
	
	// MARK: - RecurrenceEndingTableViewControllerDelegate
	
	func recurrenceEndingTableViewControllerDidChange(_ controller: RecurrenceEndingTableViewController) {
		if let task = task as? Task, let recurrence = task.recurrence {
			recurrence.endAfterDate = controller.endAfterDate
			recurrence.endAfterCount = controller.endAfterCount as NSNumber?
		}
		updateControls()
	}
	
	// MARK: - Table View Delegate
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let recurringCells = recurringCells, let oneTimeCells = oneTimeCells else {
			return super.tableView(tableView, numberOfRowsInSection: section)
		}
		
		if scheduledSwitch.isOn && recurringSegmentedControl.selectedSegmentIndex == 1 {
			return recurringCells.count
		}
		else {
			return oneTimeCells.count
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let recurringCells = recurringCells, let oneTimeCells = oneTimeCells else {
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
		
		if scheduledSwitch.isOn && recurringSegmentedControl.selectedSegmentIndex == 1 {
			return recurringCells[indexPath.row]
		}
		else {
			return oneTimeCells[indexPath.row]
		}
	}
}
