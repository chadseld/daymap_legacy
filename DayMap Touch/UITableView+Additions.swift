//
//  UITableView+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 4/27/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//enum TableViewDataToManagedObjectRelationship {
//	case equals
//	case contains
//	case none
//}

protocol TableSectionObject {
	var sectionValue: Any { get }
	var children: [Any]? { get }
}

extension UITableView {
	
	func reloadData(sectionObjectsBeforeUpdate: [TableSectionObject], sectionObjectsAfterUpdate: [TableSectionObject], objectHash: (Any) -> String, additionalIndexesUpdated: [IndexPath]) {
		self.beginUpdates()
		
		let sortedSectionHashesBeforeUpdate = sectionObjectsBeforeUpdate.map { objectHash($0) }
		let sortedSectionHashesAfterUpdate = sectionObjectsAfterUpdate.map { objectHash($0) }
		
		// Deleted Sections
		let deletedSections = Set(sortedSectionHashesBeforeUpdate).subtracting(sortedSectionHashesAfterUpdate)
		if deletedSections.isEmpty == false {
			var deletedSectionsIndexSet = IndexSet()
			for sectionHash in deletedSections {
				deletedSectionsIndexSet.insert(sortedSectionHashesBeforeUpdate.firstIndex(of: sectionHash)!)
			}
			
			log_debug("Deleting sections \(deletedSectionsIndexSet)")
			self.deleteSections(deletedSectionsIndexSet, with: .automatic)
		}

		// Inserted Sections
		let insertedSections = Set(sortedSectionHashesAfterUpdate).subtracting(sortedSectionHashesBeforeUpdate)
		if insertedSections.isEmpty == false {
			var insertedSectionsIndexSet = IndexSet()
			for sectionHash in insertedSections {
				insertedSectionsIndexSet.insert(sortedSectionHashesAfterUpdate.firstIndex(of: sectionHash)!)
			}
			
			log_debug("Inserting sections \(insertedSectionsIndexSet)")
			self.insertSections(insertedSectionsIndexSet, with: .automatic)
		}
		
		// Sections that were neither deleted nor Inserted
		let remainingSectionHashes = Set(sortedSectionHashesAfterUpdate).subtracting(insertedSections)
		if remainingSectionHashes.isEmpty == false {
			for (section, sectionHash) in remainingSectionHashes.enumerated() {
				// Inspect section tasks for deletion or insertion
				let beforeSection = sectionObjectsBeforeUpdate[sortedSectionHashesBeforeUpdate.firstIndex(of: sectionHash)!]
				let afterSection = sectionObjectsAfterUpdate[sortedSectionHashesAfterUpdate.firstIndex(of: sectionHash)!]
				guard let beforeSectionChildren = beforeSection.children else {
					continue
				}
				guard let afterSectionChildren = afterSection.children else {
					continue
				}
				let sortedTaskHashesBeforeUpdate = beforeSectionChildren.map { objectHash($0) }
				let sortedTaskHashesAfterUpdate = afterSectionChildren.map { objectHash($0) }
				
				// Deleted Tasks
				let deleted = Set(sortedTaskHashesBeforeUpdate).subtracting(sortedTaskHashesAfterUpdate)
				if deleted.isEmpty == false {
					let deletedIndexes = deleted.map { IndexPath(row: sortedTaskHashesBeforeUpdate.firstIndex(of: $0)!, section: section) }

					log_debug("Deleting rows \(deletedIndexes)")
					self.deleteRows(at: deletedIndexes, with: .automatic)
				}

				// Inserted Tasks
				let inserted = Set(sortedTaskHashesAfterUpdate).subtracting(sortedTaskHashesBeforeUpdate)
				if inserted.isEmpty == false {
					let insertedIndexes = inserted.map { IndexPath(row: sortedTaskHashesAfterUpdate.firstIndex(of: $0)!, section: section) }

					log_debug("Inserting rows \(insertedIndexes)")
					self.insertRows(at: insertedIndexes, with: .automatic)
				}
			}
		}
		
		// Perform additionalIndexesUpdated
		if additionalIndexesUpdated.isEmpty == false {
			var additionalIndexesUpdatedMinusFirstResponder = additionalIndexesUpdated
			
			// If one of the table view's rows is the first responder, remove
			// it from the list of index paths to reload
			if let firstResponder = UIResponder.firstResponder as? UIView, firstResponder.isDescendant(of: self) {
				for (i, indexPath) in additionalIndexesUpdatedMinusFirstResponder.enumerated() {
					if let cell = self.cellForRow(at: indexPath) {
						if firstResponder.isDescendant(of: cell) {
							additionalIndexesUpdatedMinusFirstResponder.remove(at: i)
							break
						}
					}
				}
			}
			
			if additionalIndexesUpdatedMinusFirstResponder.isEmpty == false {
				log_debug("Reloading rows \(additionalIndexesUpdatedMinusFirstResponder.map { $0.row })")
				self.reloadRows(at: additionalIndexesUpdatedMinusFirstResponder, with: .automatic)
			}
		}
		
		self.endUpdates()
	}
	
	// Note: Could extend this to work with table views that don't directly host NSManagedObject's in their data source. For example, the Week View is a list of days (which contain NSManagedObject's indirectly).
	// Could do this by providing an concernedCallback block for the caller to implement.
	// The block could take an objectID and return .equal or .containing
	// Then, for example, Deleted stage could use the return to determine which rows to delete, vs simply reload. Inserted and Updated stages would take similar action.
	// The objectsBeforeUpdate would have to be [Any]
	
//	func reloadData(objectsBeforeUpdate: [Any], objectsAfterUpdate: [Any], objectRelationship: (_ object: Any, _ managedObject: NSManagedObject) -> TableViewDataToManagedObjectRelationship managedObjectContextObjectsDidChangeNotification notification: Notification) {
	
	// For Table Views that represent a list of NSManagedObjects. No support for sections.
	func reloadData(objectsBeforeUpdate: [NSManagedObject], objectsAfterUpdate: [NSManagedObject], managedObjectContextObjectsDidChangeNotification notification: Notification) {
		self.beginUpdates()
		
		let sortedIDsBeforeUpdate = objectsBeforeUpdate.map { $0.objectID }
		let sortedIDsAfterUpdate = objectsAfterUpdate.map { $0.objectID }

		// Deleted
		let deleted = Set(sortedIDsBeforeUpdate).subtracting(sortedIDsAfterUpdate)
		if deleted.isEmpty == false {
			let deletedIndexes = deleted.map { IndexPath(row: sortedIDsBeforeUpdate.firstIndex(of: $0)!, section:0) }
			
			log_debug("Deleting rows \(deletedIndexes.map { $0.row })")
			self.deleteRows(at: deletedIndexes, with: .automatic)
		}
		
		// Inserted
		let inserted = Set(sortedIDsAfterUpdate).subtracting(sortedIDsBeforeUpdate)
		if inserted.isEmpty == false {
			let insertedIndexes = inserted.map { IndexPath(row: sortedIDsAfterUpdate.firstIndex(of: $0)!, section:0) }
			
			log_debug("Inserting rows \(insertedIndexes.map { $0.row })")
			self.insertRows(at: insertedIndexes, with: .automatic)
		}
		
		// Updated
		let updated = NSManagedObjectContext.objectIDsUpdatedRefreshedOrInvalidatedByNotification(notification)
		if updated.isEmpty == false {
			var updatedIndexes = updated.filter { sortedIDsBeforeUpdate.contains($0) && sortedIDsAfterUpdate.contains($0) }
				.map { IndexPath(row: sortedIDsBeforeUpdate.firstIndex(of: $0)!, section:0) }
			
			if updatedIndexes.isEmpty == false {
				// If one of the table view's rows is the first responder, remove
				// it from the list of index paths to reload
				if let firstResponder = UIResponder.firstResponder as? UIView, firstResponder.isDescendant(of: self) {
					for (i, indexPath) in updatedIndexes.enumerated() {
						if let cell = self.cellForRow(at: indexPath) {
							if firstResponder.isDescendant(of: cell) {
								updatedIndexes.remove(at: i)
								break
							}
						}
					}
				}
				
				if updatedIndexes.isEmpty == false {
					log_debug("Reloading rows \(updatedIndexes.map { $0.row })")
					self.reloadRows(at: updatedIndexes, with: .automatic)
				}
			}
		}
		
		self.endUpdates()
	}
}
