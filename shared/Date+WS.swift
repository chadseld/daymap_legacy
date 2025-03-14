//
//  Date+WS.swift
//  DayMap
//
//  Created by Chad Seldomridge on 6/8/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Foundation

fileprivate let GMTCalendar: NSCalendar = {
	var calendar = NSCalendar.current as NSCalendar
	calendar.timeZone = TimeZone(abbreviation: "GMT")!
	return calendar
}()

fileprivate let localCalendar: NSCalendar = {
	var calendar = NSCalendar.current as NSCalendar
	calendar.timeZone = NSTimeZone.local
	return calendar
}()

extension Date {
	private var quantizedToMonth: Date {
		let components = GMTCalendar.components([.year, .month], from: self)
		let day = GMTCalendar.date(from: components)!
		return day;
	}
	
	private var quantizedToSunday: Date {
		// Get the weekday component of the current date
		let weekdayComponents = GMTCalendar.components(.weekday, from: self)
		
		/*
		Create a date components to represent the number of days to subtract from the current date.
		The weekday value for Sunday in the Gregorian calendar is 1, so subtract 1 from the number of days to subtract from the date in question.  (If today is Sunday, subtract 0 days.)
		*/
		var componentsToSubtract = DateComponents()
		componentsToSubtract.day = 0 - weekdayComponents.weekday! - 1
		
		let beginningOfWeek = GMTCalendar.date(byAdding: componentsToSubtract, to: self)!
		
		/*
		Optional step:
		beginningOfWeek now has the same hour, minute, and second as the original date (today).
		To normalize to midnight, extract the year, month, and day components and create a new date from those components.
		*/
		return beginningOfWeek.quantizedToDay
	}
	
	var quantizedToDay: Date {
		let components = GMTCalendar.components([.year, .month, .day], from: self)
		let day = GMTCalendar.date(from: components)!
		return day;
	}
	
	var beginningOfMonth: Date {
		var beginningOfMonth: NSDate?
		let success = GMTCalendar.range(of: .month, start: &beginningOfMonth, interval: nil, for: self)
		
		if let beginningOfMonth = beginningOfMonth, success == true {
			return beginningOfMonth as Date
		}
		
		return self.quantizedToMonth
	}
	
	var beginningOfWeek: Date {
		var beginningOfWeek: NSDate?
		let success = GMTCalendar.range(of: .weekOfYear, start: &beginningOfWeek, interval: nil, for: self)
		
		if let beginningOfWeek = beginningOfWeek, success == true {
			return beginningOfWeek as Date
		}
		
		return self.quantizedToSunday
	}
	
	var promotedToCurrentWeek: Date {
		let currentWeek = Date().quantizedToSunday
		let weekdayComponents = GMTCalendar.components(.weekday, from: self)
		return currentWeek.adding(days: weekdayComponents.weekday! - 1)
	}
	
	static var today: Date {
		let components = localCalendar.components([.year, .month, .day], from: Date())
		return GMTCalendar.date(from: components)!
	}
	
	// MARK: - Adding
	
	func adding(days: Int) -> Date {
		var components = DateComponents()
		components.day = days
		let day = GMTCalendar.date(byAdding: components, to: self)!
		return day
	}
	
	func adding(weeks: Int) -> Date {
		var components = DateComponents()
		components.weekOfYear = weeks
		let day = GMTCalendar.date(byAdding: components, to: self)!
		return day
	}
	
	func adding(months: Int) -> Date {
		var components = DateComponents()
		components.month = months
		let day = GMTCalendar.date(byAdding: components, to: self)!
		return day
	}
	
	func adding(years: Int) -> Date {
		var components = DateComponents()
		components.year = years
		let day = GMTCalendar.date(byAdding: components, to: self)!
		return day
	}
	
	// MARK: - Comparison
	
	func isWithinOneSecondOf(_ otherDate: Date) -> Bool {
		return fabs(self.timeIntervalSinceReferenceDate - otherDate.timeIntervalSinceReferenceDate) < 1
	}
	
	func isLaterThan(_ otherDate: Date) -> Bool {
		return self.compare(otherDate) == .orderedDescending
	}
	
	func isLaterThanOrEqualTo(_ otherDate: Date) -> Bool {
		let result = self.compare(otherDate)
		return result == .orderedDescending || result == .orderedSame
	}
	
	func isEarlierThan(_ otherDate: Date) -> Bool {
		return self.compare(otherDate) == .orderedAscending
	}
	
	func isEarlierThanOrEqualTo(_ otherDate: Date) -> Bool {
		let result = self.compare(otherDate)
		return result == .orderedAscending || result == .orderedSame
	}
}
