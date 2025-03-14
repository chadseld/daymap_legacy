//
//  Task+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/11/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import CoreData
#if os(macOS)
import AppKit
#endif

enum TaskCompletedState: Int {
	case notCompleted = 0
	case completed = 1
	case partiallyCompleted = -1
	
	var advance: TaskCompletedState {
		switch self {
		case .notCompleted:
			return .completed
		case .completed:
			return .notCompleted
		case .partiallyCompleted:
			return .completed
		}
	}
	
	var advancePartial: TaskCompletedState {
		switch self {
		case .notCompleted:
			return .partiallyCompleted
		case .completed:
			return .partiallyCompleted
		case .partiallyCompleted:
			return .completed
		}
	}
	
	#if os(macOS)
	init(_ source: NSControl.StateValue) {
		switch source {
		case .on:
			self = .completed
		case .off:
			self = .notCompleted
		case .mixed:
			self = .partiallyCompleted
		default:
			self = .notCompleted
		}
	}
	
	var controlStateValue: NSControl.StateValue {
		switch self {
		case .notCompleted:
			return .off
		case .completed:
			return .on
		case .partiallyCompleted:
			return .mixed
		}
	}
	#endif
}

extension Task {
		
	override public func awakeFromInsert() {
		super.awakeFromInsert()
		
		if self.uuid == nil {
			self.uuid = CreateUUID()
			self.createdDate = Date()
			self.name = "Untitled Task"
		}
	}
	
	override public func willSave() {
		super.willSave()
		
		if !self.isDeleted &&
			!(self.modifiedDate?.isWithinOneSecondOf(Date()) ?? false) {
			self.modifiedDate = Date()
		}
	}
	
	// MARK: - Recurrences
	var recurringEndDate: Date {
		guard let scheduledDate = self.scheduledDate, let recurrence = self.recurrence else {
			return Date.distantPast
		}
		
		if let endAfterDate = recurrence.endAfterDate {
			return endAfterDate
		}
		
		if let endAfterCount = self.recurrence?.endAfterCount,
			let frequencyRaw = recurrence.frequency,
			let frequency = RecurrenceFrequency(rawValue: frequencyRaw.intValue) {
			switch frequency {
			// We subtract 1 because the first recurrence is the scheduled date itself
			case .daily:
				return scheduledDate.adding(days: endAfterCount.intValue - 1)
			case .weekly:
				return scheduledDate.adding(weeks: endAfterCount.intValue - 1)
			case .monthly:
				return scheduledDate.adding(months: endAfterCount.intValue - 1)
			case .yearly:
				return scheduledDate.adding(years: endAfterCount.intValue - 1)
			case .biWeekly:
				return scheduledDate.adding(weeks: (endAfterCount.intValue - 1) * 2)
			}
		}
		
		return Date.distantFuture
	}
	
	// MARK: - Completed
	
	fileprivate var completedState: TaskCompletedState {
		get {
			return TaskCompletedState(rawValue: self.completed?.intValue ?? 0) ?? .notCompleted
		}
		set {
			self.completed = newValue.rawValue as NSNumber
			switch newValue {
			case .completed:
				fallthrough
			case .partiallyCompleted:
				self.completedDate = Date.today
			case .notCompleted:
				self.completedDate = nil
			}
		}
	}
	
	static func toggleCompletedState(of tasks: [Task], recurrenceQuestionHandler: RecurrenceQuestionHandler?, completion: ((_ success: Bool) -> Void)?) {
		var anyUncompleted = false
		var anyCompleted = false
		
		let date = recurrenceQuestionHandler?.recurrenceDate
		
		for task in tasks {
			if task.completedState(at: date) == .completed {
				anyCompleted = true
			}
			else {
				anyUncompleted = true
			}
		}
		
		var destinationState: TaskCompletedState
		if anyCompleted && !anyUncompleted {
			destinationState = .notCompleted
		}
		else {
			destinationState = .completed
		}
		
		var combinedSuccess = true
		let group = DispatchGroup()
		for _ in tasks {
			group.enter()
		}
		
		for task in tasks {
			task.set(completedState: destinationState, recurrenceQuestionHandler: recurrenceQuestionHandler) { success in
				combinedSuccess = success && combinedSuccess
				group.leave()
			}
		}
		
		group.notify(queue: .main) {
			completion?(combinedSuccess)
		}
	}
	
	func completedState(at date: Date? = nil) -> TaskCompletedState {
		if let date = date, let recurrence = self.recurrence, recurrence.recurs(at: date) {
			return recurrence.completedState(at: date, baseState: completedState)
		}
		else {
			return completedState
		}
	}
	
	func set(completedState state: TaskCompletedState, recurrenceQuestionHandler: RecurrenceQuestionHandler?, completion: ((_ success: Bool) -> Void)?) {
		
		let changeAll = {
			self.recurrence?.clearCompletions()
			self.completedState = state
		}
		
		if let recurrence = self.recurrence, let recurrenceQuestionHandler = recurrenceQuestionHandler, recurrence.recurs(at: recurrenceQuestionHandler.recurrenceDate) {
			
			recurrenceQuestionHandler.shouldChangeAllOccurrences() { answer in
				switch answer {
				case .changeAll:
					changeAll()
				case .changeSingleOccurrence:
					recurrence.set(completedState: state, at: recurrenceQuestionHandler.recurrenceDate)
				case .cancel:
					completion?(false)
				}
			}
		}
		else {
			changeAll()
		}
	}
	
	// MARK: - Scheduling
	
	func set(scheduledDate date: Date?, recurrenceQuestionHandler: RecurrenceQuestionHandler?, completion: ((_ success: Bool) -> Void)?) {
		let changeAll = {
			self.recurrence?.clearExceptions()
			self.recurrence?.clearSortIndexes()
			self.scheduledDate = date
			if date == nil {
				self.sortIndexInDay = -1
				self.recurrence = nil
			}
			completion?(true)
		}
		
		let changeSingleOccurrence = {
			guard let recurrenceQuestionHandler = recurrenceQuestionHandler else {
				completion?(false)
				return
			}
			
			self.recurrence?.addException(at: recurrenceQuestionHandler.recurrenceDate)
			self.recurrence?.set(sortIndex: -1, at: recurrenceQuestionHandler.recurrenceDate)
			
			if let date = date {
				if let cloned = self.clone() as? Task {
					cloned.name = (cloned.name ?? "") + " " + NSLocalizedString("(rescheduled)", comment: "rescheduled task name")
					cloned.recurrence = nil
					cloned.scheduledDate = date
					self.parent?.addToChildren(cloned)
				}
			}
			completion?(true)
		}
		
		guard let recurrenceQuestionHandler = recurrenceQuestionHandler, let recurrence = self.recurrence else {
			changeAll()
			return
		}
		
		if recurrence.recurs(at: recurrenceQuestionHandler.recurrenceDate) {
			recurrenceQuestionHandler.shouldChangeAllOccurrences() { answer in
				switch answer {
				case .changeAll:
					changeAll()
				case .changeSingleOccurrence:
					changeSingleOccurrence()
				case .cancel:
					completion?(false)
				}
			}
		}
		else {
			changeAll()
		}
	}
    
    // MARK: - Dragging
    
    @objc static let dragDataType: String = "com.whetstoneaps.daymap.task.uuid"
}

// MARK: - Helper Protocols

enum RecurrenceQuestionAnswer {
	case changeAll
	case changeSingleOccurrence
	case cancel
}

protocol RecurrenceQuestionHandler: class {
	var recurrenceDate: Date { get }
	func shouldChangeAllOccurrences(completion: @escaping (_ answer: RecurrenceQuestionAnswer) -> Void)
}
