//
//  AbstractTask+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/11/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import CoreData

extension AbstractTask {
	@objc dynamic var attributedDetailsString: NSAttributedString? {
		get {
			if let data = self.attributedDetails {
				return try? NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.rtf], documentAttributes: nil)
			}
			return nil
		}
		set {
			if let attributedString = newValue, attributedString.length > 0 {
				do {
					let data = try attributedString.data(from: NSMakeRange(0, attributedString.length), documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType : NSAttributedString.DocumentType.rtf])
					self.attributedDetails = data
				}
				catch {
					log_error("Error converting attributed string: \(error)")
					self.attributedDetails = nil
				}
			}
			else {
				self.attributedDetails = nil
			}
		}
	}
	
	override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
		var paths = super.keyPathsForValuesAffectingValue(forKey: key)
		switch key {
		case "attributedDetailsString":
			paths = paths.union(["attributedDetails"])
		default:
			break
		}
		return paths
	}
	
	var rootProject: Project? {
		// If it's a Task, Traverse up the tree to the root project
		// Don't traverse up if it's a Project, because its already a the top.
		var root: AbstractTask? = self
		var nextUp: AbstractTask? = root?.parent
		while root?.entity.name == "Task" && nextUp != nil {
			root = nextUp
			nextUp = root?.parent
		}
		
		// Use a conditional as? in case we have an orphaned Task with no Project parent (db madness can happen since programmers are human)
		return root as? Project
	}
}
