//
//  NSManagedObjectContext+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 1/5/18.
//  Copyright © 2018 Whetstone Apps. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
	static func areObjectsDeletedByNotification(objects: [NSManagedObject], notification: Notification) -> Bool {
		let deletedIDs = objectIDsDeletedByNotification(notification)
		let objectIDs = objects.map { $0.objectID }
		if deletedIDs.intersection(objectIDs).isEmpty == false {
			return true
		}
		return false
	}
	
	static func areObjectsChangedByNotification(objects: [NSManagedObject], notification: Notification) -> Bool {
		let updatedIDs = objectIDsUpdatedRefreshedOrInvalidatedByNotification(notification)
		let objectIDs = objects.map { $0.objectID }
		if updatedIDs.intersection(objectIDs).isEmpty == false {
			return true
		}
		return false
	}
	
	static func objectIDsDeletedByNotification(_ notification: Notification) -> Set<NSManagedObjectID> {
		guard let userInfo = notification.userInfo,
			let deleted = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> else {
			return Set()
		}
		
		return Set(deleted.map { $0.objectID })
	}
	
	static func objectIDsInsertedByNotification(_ notification: Notification) -> Set<NSManagedObjectID> {
		guard let userInfo = notification.userInfo,
			let inserted = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> else {
				return Set()
		}
		
		return Set(inserted.map { $0.objectID })
	}
	
	static func objectIDsUpdatedRefreshedOrInvalidatedByNotification(_ notification: Notification) -> Set<NSManagedObjectID> {
		guard let userInfo = notification.userInfo else {
				return Set()
		}
		
		var objectIDs = Set<NSManagedObjectID>()
		
		if let updated = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
			objectIDs.formUnion(updated.map { $0.objectID })
		}
		
		if let refreshed = userInfo[NSRefreshedObjectsKey] as? Set<NSManagedObject> {
			objectIDs.formUnion(refreshed.map { $0.objectID })
		}
		
		if let invalidated = userInfo[NSInvalidatedObjectsKey] as? Set<NSManagedObject> {
			objectIDs.formUnion(invalidated.map { $0.objectID })
		}
		
		if let invalidated = userInfo[NSInvalidatedAllObjectsKey] as? [NSManagedObjectID] {
			objectIDs.formUnion(invalidated.map { $0 })
		}
		
		return objectIDs
	}
}
