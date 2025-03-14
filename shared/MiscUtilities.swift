//
//  MiscUtilities.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/5/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
#endif
import CoreData
import CloudKit

let SortDescriptor_SortIndex = NSSortDescriptor(key: "sortIndex", ascending: true)
let SortDescriptor_SortIndexInDay = NSSortDescriptor(key: "sortIndexInDay", ascending: true)
let SortDescriptor_ScheduledDate = NSSortDescriptor(key: "scheduledDate", ascending: true)
let SortDescriptor_ModifiedDate = NSSortDescriptor(key: "modifiedDate", ascending: false)

func CreateUUID() -> String {
	return UUID().uuidString
}

func ObjectWithUUID(_ uuid: String, in context: NSManagedObjectContext) -> NSManagedObject? {
	let entityNames = ["Task",
	                   "Project",
	                   "DayMap",
					   "Inbox",
	                   "Reminder",
	                   "Attachment",
	                   "Tag",
	                   "RecurrenceRule",
	                   "RecurrenceCompletion",
	                   "RecurrenceException",
	                   "RecurrenceSortIndex"];
	
	for name in entityNames {
		let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: name)
		fetchRequest.predicate = NSPredicate(format: "uuid = %@", uuid)
		if let result = try? context.fetch(fetchRequest) {
			return result.first
		}
	}
	
	return nil
}

func ArrayByStrippingNilValues<T>(_ input: [T?]) -> [T] {
	return input.filter { $0 != nil } as! [T]
}

#if os(macOS)
func IsOptionKeyPressed() -> Bool {
	return NSEvent.modifierFlags.contains(.option)
}
func IsCommandKeyPressed() -> Bool {
	return NSEvent.modifierFlags.contains(.command)
}
func IsControlKeyPressed() -> Bool {
	return NSEvent.modifierFlags.contains(.control)
}

func DeleteCloudKitData(zoneName: String, containerIdentifier: String) {
	log_debug("Deleting CloudKit data")
	
	let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
	let operation = CKModifyRecordZonesOperation()
	operation.recordZoneIDsToDelete = [zoneID]
	operation.queuePriority = .high
	operation.qualityOfService = .userInteractive
	
	operation.modifyRecordZonesCompletionBlock = {saved, deleted, error in
		log_debug("Deleted zone \(String(describing: deleted))")
	}
	
	let container = CKContainer(identifier: containerIdentifier)
	let database = container.privateCloudDatabase
	database.add(operation)
}
#endif
