//
//  Project+Additions.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/26/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import CoreData
#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

extension Project {
		
	override public func awakeFromInsert() {
		super.awakeFromInsert()
		
		if self.uuid == nil {
			self.uuid = CreateUUID()
			self.createdDate = Date()
			self.name = "Untitled Project"
			self.nativeColor = WSColor.randomProject
		}
	}
	
	override public func willSave() {
		super.willSave()
		
		if !self.isDeleted &&
			!(self.modifiedDate?.isWithinOneSecondOf(Date()) ?? false) {
			self.modifiedDate = Date()
		}
	}
	
	var nativeColor: WSColor? {
		set {
			guard let newValue = newValue else {
				return
			}
			
			var red: CGFloat = 0
			var green: CGFloat = 0
			var blue: CGFloat = 0
			var alpha: CGFloat = 0
			newValue.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
			let archiver = NSKeyedArchiver(requiringSecureCoding: true)
			archiver.encode(Double(red), forKey: "R")
			archiver.encode(Double(green), forKey: "G")
			archiver.encode(Double(blue), forKey: "B")
			archiver.encode(Double(alpha), forKey: "A")
			archiver.encode(true, forKey: "v4")
			archiver.finishEncoding()
			
			self.color = archiver.encodedData
		}
		get {
			guard let colorData = self.color as Data? else {
				return nil
			}
			
			do {
				let unarchiver = try NSKeyedUnarchiver(forReadingFrom: colorData)
				
				if unarchiver.containsValue(forKey: "v4") {
					let red = unarchiver.decodeDouble(forKey: "R")
					let green = unarchiver.decodeDouble(forKey: "G")
					let blue = unarchiver.decodeDouble(forKey: "B")
					let alpha = unarchiver.decodeDouble(forKey: "A")
					
					return WSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
				}
				else {
					return nil
				}
			}
			catch {
				return nil
			}
		}
	}
}
