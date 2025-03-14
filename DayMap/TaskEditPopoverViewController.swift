//
//  TaskEditPopoverViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 1/3/18.
//  Copyright © 2018 Whetstone Apps. All rights reserved.
//

import Cocoa

class TaskEditPopoverViewController: NSViewController, TaskConsumer, CurrentDayConsumer, CoreDataConsumer {

	// MARK: - CoreDataConsumer
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			updateDetails()
			
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
	
	@objc dynamic var task: AbstractTask? = nil {
		didSet {
			updateDetails()
		}
	}
	
	// MARK: - CurrentDayConsumer
	
	var currentDay: Date? = Date.today
	
	// MARK: - Private
	
	@IBOutlet weak var completedCheckbox: NSButton!
	@IBOutlet weak var nameTextField: NSTextField!
	@IBOutlet weak var scheduledDatePicker: NSDatePicker!
	@IBOutlet weak var endDatePicker: NSDatePicker!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		scheduledDatePicker.timeZone = TimeZone(abbreviation: "GMT")
		endDatePicker.timeZone = TimeZone(abbreviation: "GMT")

		updateDetails()
    }
	
	override func viewWillAppear() {
		super.viewWillAppear()
		self.view.window?.initialFirstResponder = nameTextField
	}
	
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			if let task = self.task as? Task {
				if NSManagedObjectContext.areObjectsDeletedByNotification(objects: [task], notification: notification) {
					self.closePopover()
				}
				
				if NSManagedObjectContext.areObjectsChangedByNotification(objects: ArrayByStrippingNilValues([task, task.recurrence]), notification: notification) {
					self.updateDetails()
				}
			}
		}
	}
	
	private func updateDetails() {
		guard let _ = completedCheckbox, let task = task as? Task else {
			return
		}
		// use bindings where you can
		// some things need special work and won't work as bindings
			// completed status (depends on day and can also be partial)
			// scheduledDay, when set, needs to clear recurrence exceptions
			// changes to recurrence rule change menu options etc...
			// attributedDetailsString is not KVO compliant (is backed by attributedDetails NSData)

		// Scheduled Date
		willChangeValue(for: \.scheduledDate)
		didChangeValue(for: \.scheduledDate)
		
		// Completed Checkbox
		let state = task.completedState(at: currentDay)
		completedCheckbox.allowsMixedState = (state == .partiallyCompleted)
		completedCheckbox.state = state.controlStateValue
	}

	private func closePopover() {
		// TODO: - close popover
	}
	
	// MARK: - Interface Changes

	@IBAction func toggleCompleted(_ sender: Any) {
		if let task = task as? Task {
			let state = task.completedState(at: currentDay)//TaskCompletedState(completedCheckbox.state)
			
			let destinationState: TaskCompletedState
			if IsOptionKeyPressed() {
				destinationState = state.advancePartial
			}
			else {
				destinationState = state.advance
			}
			
			let updateControl: (_: TaskCompletedState) -> Void = { state in
				self.completedCheckbox.allowsMixedState = (state == .partiallyCompleted)
				self.completedCheckbox.state = state.controlStateValue
			}
			
			// Override the current state of the button, set by AppKit during the click
			updateControl(destinationState)
			
			if let currentDay = currentDay {
				let handler = SheetStyleRecurrenceQuestionHandler(recurrenceDate: currentDay, parentViewController: self)
				task.set(completedState: destinationState, recurrenceQuestionHandler: handler) { success in
					updateControl(task.completedState(at: self.currentDay))
				}
			}
			else {
				task.set(completedState: destinationState, recurrenceQuestionHandler: nil) { success in
					updateControl(task.completedState(at: self.currentDay))
				}
			}
		}
	}
	
	@objc dynamic var scheduledDate: Date? {
		get {
			if let task = task as? Task {
				return task.scheduledDate
			}
			return nil
		}
		set {
			if let task = task as? Task {
				task.scheduledDate = newValue?.quantizedToDay
				task.recurrence?.clearExceptions()
			}
		}
	}

	@IBAction func clearScheduledDate(_ sender: Any) {
		scheduledDate = nil
	}
	
	@IBAction func scheduleForToday(_ sender: Any) {
		scheduledDate = Date.today
	}
	
	@IBAction func showDatePickerPopover(_ sender: NSButton) {
		DMDatePickerPopover().showRelative(to: sender.bounds, of: sender, preferredEdge: .minY, start: scheduledDate ?? Date.today) { (newDate) in
			self.scheduledDate = newDate
		}
	}
}
