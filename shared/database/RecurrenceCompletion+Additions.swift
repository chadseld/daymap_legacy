//
//  RecurrenceRule+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/11/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import CoreData

extension RecurrenceCompletion {
		
	override public func awakeFromInsert() {
		super.awakeFromInsert()
		
		if self.uuid == nil {
			self.uuid = CreateUUID()
			self.recurrenceIndex = 0 as NSNumber
			self.completed = TaskCompletedState.notCompleted.rawValue as NSNumber
		}
	}
	
	override public func willSave() {
		super.willSave()
		
		if !self.isDeleted &&
			!(self.modifiedDate?.isWithinOneSecondOf(Date()) ?? false) {
			self.modifiedDate = Date()
		}
	}
	
	var completedState: TaskCompletedState {
		get {
			return TaskCompletedState(rawValue: self.completed?.intValue ?? 0) ?? .notCompleted
		}
		set {
			self.completed = newValue.rawValue as NSNumber
		}
	}
}
