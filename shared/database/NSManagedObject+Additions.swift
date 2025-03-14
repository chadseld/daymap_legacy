//
//  NSManagedObject+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 6/30/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import CoreData

extension NSManagedObject {
	
	// Note: Caller must set the owner relationship.
	// e.g. parent, or dayMap, or task attribute. We only clone in one direction.
	func clone() -> NSManagedObject? {
		guard let entityName = self.entity.name, let context = self.managedObjectContext else {
			return nil
		}
		
		// Create new object
		let clone = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
		
		// Loop through all the attributes and assign them to the clone
		for attributeKey in self.entity.attributesByName.keys {
			clone.setValue(self.value(forKey: attributeKey), forKey: attributeKey)
		}
		
		// Assign new UUID
		clone.setValue(CreateUUID(), forKey: "uuid")
		
		// Loop through all relationships and clone them recursively
		let relationships = self.entity.relationshipsByName
		for (relationshipName, relationship) in relationships {
			// Don't walk up the tree, only down.
			if (relationshipName == "parent" || relationshipName == "dayMap" || relationshipName == "task" || relationshipName == "recurrenceRule") {
				continue
			}
			
			if relationship.isToMany {
				// Get a set of the objects in this to-many relationship
				let sourceDestinationsSet = self.mutableSetValue(forKey: relationshipName)
				let cloneDestinationsSet = clone.mutableSetValue(forKey: relationshipName)
				
				for sourceObject in sourceDestinationsSet {
					if let clonedDestinationObject = (sourceObject as! NSManagedObject).clone() {
						cloneDestinationsSet.add(clonedDestinationObject)
					}
				}
			}
			else {
				if let sourceRelationshipDestination = self.value(forKey: relationshipName) {
					if let clonedRelationshipDestination = (sourceRelationshipDestination as! NSManagedObject).clone() {
						clone.setValue(clonedRelationshipDestination, forKey: relationshipName)
					}
				}
			}
		}
		
		return clone
	}
}
