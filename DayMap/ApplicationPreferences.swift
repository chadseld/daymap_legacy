//
//  ApplicationPreferences.swift
//  DayMap
//
//  Created by Chad Seldomridge on 9/28/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import Foundation

class ApplicationPreferences: NSObject {
	static func registerDefaults() {
		UserDefaults.standard.register(defaults: ["mainSplitViewPercentageFromTop" : 0.5])
	}
	
	static var legacyICloudEnabled: Bool {
		set {
			UserDefaults.standard.set(newValue, forKey: "PrefUseiCloudStorage")
		}
		get {
			return UserDefaults.standard.bool(forKey: "PrefUseiCloudStorage")
		}
	}
	
	
	static var hideCompletedBeforeDate: Date {
		let days = self.hideCompletedAfterNumberOfDays
		if 0 == days {
			return NSDate.distantFuture
		}
		else if 91 == days {
			return NSDate.distantPast
		}
		else {
			return Date.today.adding(days: -days)
		}
	}
	
	static var hideCompletedAfterNumberOfDays: Int {
		set {
			UserDefaults.standard.set(newValue, forKey: "PrefHideCompletedAfterNumberOfDays")
		}
		get {
			return UserDefaults.standard.integer(forKey: "PrefHideCompletedAfterNumberOfDays")
		}
	}
	
	static var showArchivedProjects: Bool {
		set {
			UserDefaults.standard.set(newValue, forKey: "showArchivedProjects")
		}
		get {
			return UserDefaults.standard.bool(forKey: "showArchivedProjects")
		}
	}
	
	static var mainSplitViewPercentageFromTop: CGFloat {
		set {
			UserDefaults.standard.set(newValue, forKey: "mainSplitViewPercentageFromTop")
		}
		get {
			return CGFloat(UserDefaults.standard.float(forKey: "mainSplitViewPercentageFromTop"))
		}
	}
}
