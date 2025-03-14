//
//  RecurrenceException+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 6/30/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Foundation

extension RecurrenceException {
	
	override public func awakeFromInsert() {
		super.awakeFromInsert()
		
		if self.uuid == nil {
			self.uuid = CreateUUID()
			self.recurrenceIndex = 0 as NSNumber
		}
	}
	
	override public func willSave() {
		super.willSave()
		
		if !self.isDeleted &&
			!(self.modifiedDate?.isWithinOneSecondOf(Date()) ?? false) {
			self.modifiedDate = Date()
		}
	}
}
