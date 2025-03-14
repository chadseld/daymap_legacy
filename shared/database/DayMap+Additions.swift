//
//  DayMap+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/26/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import CoreData

extension DayMap {
	
	// The primary DayMap is created at first run. This DayMap has a constant uuid so 
	// that we can merge it with the first run DayMaps of other devices.
	// Otherwise we would have multiple DayMap objects, each with a unique uuid. -- one for each (re)install on each device.
	// Additional DayMaps objects can still be created with normal uuids, to support
	// multiple DayMap 'tabs'. But this first DayMap is shared everywhere.
	class var primaryUUID: String {
		return "001"
	}
	
	class var primaryFetchRequest: NSFetchRequest<DayMap> {
		let request: NSFetchRequest<DayMap> = DayMap.fetchRequest()
		request.predicate = NSPredicate(format: "uuid == %@", DayMap.primaryUUID)
		return request
	}
	
	static func initializePrimaryDayMap(coreDataContainer: NSPersistentContainer) {
		coreDataContainer.viewContext.performAndWait {
			if let _ = (try? coreDataContainer.viewContext.fetch(DayMap.primaryFetchRequest))?.last {
				// DayMap object has already been created
			}
			else {
				let dayMap = DayMap(context: coreDataContainer.viewContext)
				dayMap.uuid = DayMap.primaryUUID
				try? coreDataContainer.viewContext.save()
			}
		}
	}
		
	override public func awakeFromInsert() {
		super.awakeFromInsert()
		
		if self.uuid == nil {
			self.uuid = CreateUUID()
			self.dataModelVersion = 10
			self.inbox = Inbox(context: self.managedObjectContext!)
			self.inbox?.name = "Inbox"
		}
	}
	
	override public func willSave() {
		super.willSave()
		
		if !self.isDeleted &&
			!(self.modifiedDate?.isWithinOneSecondOf(Date()) ?? false) {
			self.modifiedDate = Date()
		}
	}
	
	static func deduplicatePrimaryDayMaps(context: NSManagedObjectContext) {
		guard let dayMaps = try? context.fetch(DayMap.primaryFetchRequest),
			dayMaps.count > 1 else {
			return
		}
		
		let sortedDayMaps = dayMaps.sorted { (a, b) -> Bool in
			guard let a_modifiedDate = a.modifiedDate, let b_modifiedDate = b.modifiedDate else {
				return false
			}
			return a_modifiedDate.isEarlierThanOrEqualTo(b_modifiedDate)
		}
		
		let firstDayMap = sortedDayMaps[0]
	
		for dayMap in sortedDayMaps[1...] {
			if let projects = dayMap.projects {
				firstDayMap.addToProjects(projects)
			}
			if let inbox = dayMap.inbox, let children = inbox.children, let firstInbox = firstDayMap.inbox {
				firstInbox.addToChildren(children)
				context.delete(inbox)
			}
			context.delete(dayMap)
		}
	}
}
