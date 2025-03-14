//
//  RecurrenceRule+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/11/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import CoreData

typealias RecurrenceIndex = Int

enum RecurrenceFrequency: Int {
	case daily = 0
	case weekly
	case monthly
	case yearly
	case biWeekly
	
	var stringValue: String {
		switch self {
		case .daily:
			return NSLocalizedString("Daily", comment: "Recurrence frequency")
		case.weekly:
			return NSLocalizedString("Weekly", comment: "Recurrence frequency")
		case .monthly:
			return NSLocalizedString("Monthly", comment: "Recurrence frequency")
		case .yearly:
			return NSLocalizedString("Yearly", comment: "Recurrence frequency")
		case .biWeekly:
			return NSLocalizedString("Bi-Weekly", comment: "Recurrence frequency")
		}
	}
}

extension RecurrenceRule {
		
	override public func awakeFromInsert() {
		super.awakeFromInsert()
		
		if self.uuid == nil {
			self.uuid = CreateUUID()
			self.endAfterDate = nil
			self.endAfterCount = 3
			self.frequency = RecurrenceFrequency.daily.rawValue as NSNumber
		}
	}
	
	override public func willSave() {
		super.willSave()
		
		if !self.isDeleted &&
			!(self.modifiedDate?.isWithinOneSecondOf(Date()) ?? false) {
			self.modifiedDate = Date()
		}
	}
	
	static let calendar: NSCalendar = {
		var cal = Calendar.current as NSCalendar
		cal.timeZone = TimeZone(abbreviation:"GMT")!
		return cal
	}()
	
	var recurrenceFrequency: RecurrenceFrequency? {
		get {
			return RecurrenceFrequency(rawValue: self.frequency?.intValue ?? 0)
		}
		set {
			self.frequency = (newValue?.rawValue ?? 0) as NSNumber
		}
	}
	
	static func tasks(recurringOn day: Date, in context: NSManagedObjectContext) -> [Task] {
		// Fetch all recurring tasks
		let request: NSFetchRequest<Task> = Task.fetchRequest()
		request.predicate = NSPredicate(format: "scheduledDate != nil AND recurrence != nil")
		do {
			let result = try context.fetch(request)
			return recurrences(of: result, on: day, filterExceptions: true).map { $0.task }
		}
		catch {
			return []
		}
	}
	
	static func recurrences(of tasks: [Task], on day: Date, filterExceptions: Bool) -> [(task: Task, index: RecurrenceIndex)] {
		var tasksForDay: [(task: Task, index: RecurrenceIndex)] = []
		
		let startOfDay = day.quantizedToDay
		let endOfDay = startOfDay.adding(days: 1)
		
		if tasks.count == 0 {
			return [] // no matches
		}
		
		var filteredCandidates = tasks
		
		// Filter to remove all with scheduled date later than day (not started yet)
		// Also removes tasks that are not scheduled at all
		filteredCandidates = filteredCandidates.filter { (task) -> Bool in
			if let scheduledDate = task.scheduledDate {
				return endOfDay.isLaterThan(scheduledDate)
			}
			return false
		}
		
		// Filter to remove all with end date before day
		filteredCandidates = filteredCandidates.filter { (task) -> Bool in
			return startOfDay.isEarlierThanOrEqualTo(task.recurringEndDate)
		}
		
		// Optimization to remove canditates that can be easily checked with modulo days against start date
		for index in (0 ..< filteredCandidates.count).reversed() {
			let task = filteredCandidates[index]
			if let rawFrequency = task.recurrence?.frequency?.intValue, let recurrenceFrequency = RecurrenceFrequency(rawValue: rawFrequency) {

				let components = RecurrenceRule.calendar.components(.day, from: task.scheduledDate!, to: startOfDay, options: [])
				
				guard let numberOfDays = components.day else {
					continue
				}

				// Cheat here for daily/weekly/bi-weekly tasks. We can check the start date and schedule them w/o having to check further
				switch recurrenceFrequency {
				case .daily:
					if numberOfDays >= 0 {
						tasksForDay.append((task: task, index: numberOfDays))
						filteredCandidates.remove(at: index)
					}
				case .weekly:
					if (numberOfDays % 7) == 0 && numberOfDays >= 0 {
						tasksForDay.append((task: task, index: numberOfDays / 7))
						filteredCandidates.remove(at: index)
					}
				case .biWeekly:
					if (numberOfDays % 14) == 0 && numberOfDays >= 0 {
						tasksForDay.append((task: task, index: numberOfDays / 14))
						filteredCandidates.remove(at: index)
					}
				default:
					continue
				}
			}
		}
		
		if filteredCandidates.count == 0 {
			if filterExceptions {
				tasksForDay = tasksForDay.filter { $0.task.recurrence?.hasRecurrenceException(at: day) == false }
			}
			return tasksForDay
		}

		// now we have a small list of candidates
		// For each frequency [month, year], since we have already accounted for day and week
		// Starting at day, walk backwards by frequency duration until earlier than the earliest scheduled date of the candidates
		// Checking if we have a hit at any point
		filteredCandidates = (filteredCandidates as NSArray).sortedArray(using: [SortDescriptor_ScheduledDate]) as! [Task]
		for frequency in [RecurrenceFrequency.monthly, .yearly] {
			if filteredCandidates.count == 0 {
				continue
			}
			
			var proposedDate = startOfDay
			let earliestScheduledDateOfCandidates = filteredCandidates[0].scheduledDate!
			var recurrenceCount = 0
			while proposedDate.isLaterThanOrEqualTo(earliestScheduledDateOfCandidates) && filteredCandidates.count > 0 {
				let proposedStartOfDay = proposedDate
				let proposedEndOfDay = proposedStartOfDay.adding(days: 1)
				
				// For all candidates
				for index in (0 ..< filteredCandidates.count).reversed() {
					let task = filteredCandidates[index]
					
					
					// Check if matches proposed day
					if let rawFrequency = task.recurrence?.frequency?.intValue, let recurrenceFrequency = RecurrenceFrequency(rawValue: rawFrequency) {
						if recurrenceFrequency == frequency &&
							task.scheduledDate!.isLaterThanOrEqualTo(proposedStartOfDay) &&
							task.scheduledDate!.isEarlierThan(proposedEndOfDay) {
							tasksForDay.append((task: task, index: recurrenceCount))
							filteredCandidates.remove(at: index)
						}
					}
				}
				
				// Decrement by frequency duration
				switch frequency {
				case .monthly:
					proposedDate = proposedDate.adding(months: -1)
				case .yearly:
					proposedDate = proposedDate.adding(years: -1)
				default:
					break // breaks the switch, not the for
				}
				
				recurrenceCount += 1
			}
		}
		
		if filterExceptions {
			tasksForDay = tasksForDay.filter { $0.task.recurrence?.hasRecurrenceException(at: day) == false }
		}
		return tasksForDay
	}
	
	func recurs(at date: Date) -> Bool {
		if let _ = recurrenceIndex(at: date) {
			return true
		}
		return false
	}
	
	fileprivate func recurrenceIndex(at date: Date) -> RecurrenceIndex? {
		guard let task = self.task else {
			return nil
		}
		
		let matches = RecurrenceRule.recurrences(of: [task], on: date, filterExceptions: false)

		if let first = matches.first {
			return first.index
		}
		
		return nil
	}
	
	// MARK: - Completions
	
	fileprivate func recurrenceCompletion(at date: Date) -> RecurrenceCompletion? {
		guard let completions = self.completions, completions.count > 0 else {
			return nil
		}
		
		guard let recurrenceIndex = recurrenceIndex(at: date) else {
			return nil
		}
		
		guard let moc = self.managedObjectContext else {
			return nil
		}
		
		let request: NSFetchRequest<RecurrenceCompletion> = RecurrenceCompletion.fetchRequest()
		request.predicate = NSPredicate(format: "recurrenceRule.uuid = %@ AND recurrenceIndex = %@", self.uuid!, recurrenceIndex as NSNumber)
		if let result = try? moc.fetch(request) {
			return result.first
		}
		return nil
	}
	
	fileprivate func createRecurrenceCompletion(index: RecurrenceIndex) -> RecurrenceCompletion? {
		guard let context = self.managedObjectContext else {
			return nil
		}
		
		let completion = RecurrenceCompletion(context: context)
		completion.recurrenceIndex = index as NSNumber
		self.addToCompletions(completion)
		
		return completion
	}
	
	func completedState(at date : Date, baseState: TaskCompletedState) -> TaskCompletedState {
		if let completion = recurrenceCompletion(at: date) {
			return completion.completedState
		}
		else {
			return baseState
		}
	}
	
	func set(completedState state: TaskCompletedState, at date: Date) {
		var completion = recurrenceCompletion(at: date)
		
		// Instead of simply changing the completion.completedState property, we always delete and create
		// a new completion object. This is so that the MOC change notification will include in a change
		// to ourTask.recurrence.completions, and we don't have to inspect the MOC change for each and every
		// ourTask.recurrence.completions[n] object.
		if let completion = completion {
			self.managedObjectContext?.delete(completion)
		}

		if let index = recurrenceIndex(at: date) {
			completion = createRecurrenceCompletion(index: index)
		}
		
		completion?.completedState = state
	}
	
	func clearCompletions() {
		if let completions = self.completions {
			for obj in completions {
				self.managedObjectContext?.delete(obj as! NSManagedObject)
			}
		}
	}
	
	// MARK: - Exceptions
	
	fileprivate func recurrenceException(at date: Date) -> RecurrenceException? {
		guard let exceptions = self.exceptions, exceptions.count > 0 else {
			return nil
		}
		
		guard let recurrenceIndex = recurrenceIndex(at: date) else {
			return nil
		}
		
		guard let moc = self.managedObjectContext else {
			return nil
		}
		
		let request: NSFetchRequest<RecurrenceException> = RecurrenceException.fetchRequest()
		request.predicate = NSPredicate(format: "recurrenceRule.uuid = %@ AND recurrenceIndex = %@", self.uuid!, recurrenceIndex as NSNumber)
		if let result = try? moc.fetch(request) {
			return result.first
		}
		return nil
	}
	
	fileprivate func createRecurrenceException(index: RecurrenceIndex) -> RecurrenceException? {
		guard let context = self.managedObjectContext else {
			return nil
		}
		
		let exception = RecurrenceException(context: context)
		exception.recurrenceIndex = index as NSNumber
		self.addToExceptions(exception)
		
		return exception
	}
	
	func hasRecurrenceException(at date: Date) -> Bool {
		return recurrenceException(at: date) != nil
	}
	
	func addException(at date: Date) {
		guard hasRecurrenceException(at: date) == false else {
			return
		}
		
		if let index = recurrenceIndex(at: date) {
			_ = createRecurrenceException(index: index)
		}
	}
	
	func clearExceptions() {
		if let exceptions = self.exceptions {
			for obj in exceptions {
				self.managedObjectContext?.delete(obj as! NSManagedObject)
			}
		}
	}
	
	// MARK: - Sorting
	
	fileprivate func recurrenceSortIndex(at date: Date) -> RecurrenceSortIndex? {
		guard let sortIndexes = self.sortIndexes, sortIndexes.count > 0 else {
			return nil
		}
		
		guard let recurrenceIndex = recurrenceIndex(at: date) else {
			return nil
		}
		
		guard let moc = self.managedObjectContext else {
			return nil
		}
		
		let request: NSFetchRequest<RecurrenceSortIndex> = RecurrenceSortIndex.fetchRequest()
		request.predicate = NSPredicate(format: "recurrenceRule.uuid = %@ AND recurrenceIndex = %@", self.uuid!, recurrenceIndex as NSNumber)
		if let result = try? moc.fetch(request) {
			return result.first
		}
		return nil
	}
	
	fileprivate func createRecurrenceSortIndex(index: RecurrenceIndex) -> RecurrenceSortIndex? {
		guard let context = self.managedObjectContext else {
			return nil
		}
		
		let sortIndex = RecurrenceSortIndex(context: context)
		sortIndex.recurrenceIndex = index as NSNumber
		self.addToSortIndexes(sortIndex)
		
		return sortIndex
	}
	
	func sortIndex(at date: Date) -> Int {
		if let sortIndex = recurrenceSortIndex(at: date), let sortIndexInDay = sortIndex.sortIndexInDay {
			return sortIndexInDay.intValue
		}
		return -1
	}
	
	func set(sortIndex: Int, at date: Date) {
		if let recurrenceSortIndex = self.recurrenceSortIndex(at: date) {
			if sortIndex == -1 {
				self.managedObjectContext?.delete(recurrenceSortIndex)
			}
			else {
				self.willChangeValue(forKey: "sortIndexes")
				recurrenceSortIndex.sortIndexInDay = sortIndex as NSNumber
				self.didChangeValue(forKey: "sortIndexes")
			}
		}
		else if sortIndex >= 0 {
			if let index = recurrenceIndex(at: date) {
				let recurrenceSortIndex = createRecurrenceSortIndex(index: index)
				recurrenceSortIndex?.sortIndexInDay = sortIndex as NSNumber
			}
		}
	}
	
	func clearSortIndexes() {
		if let indexes = self.sortIndexes {
			for obj in indexes {
				self.managedObjectContext?.delete(obj as! NSManagedObject)
			}
		}
	}
}
