//
//  ApplicationPaths.swift
//  DayMap
//
//  Created by Chad Seldomridge on 7/3/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import Foundation
import CoreData

class ApplicationPaths: NSObject {
	static var applicationSupportFolder: URL? = {
		guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last, let bundleIdentifier = Bundle.main.bundleIdentifier else {
			return nil
		}

		do {
			let url = appSupportURL.appendingPathComponent(bundleIdentifier)
			try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
			return url
		}
		catch {
			return nil
		}
	}()
	
	static var applicationGroupContainer: URL? = {
		let appGroupName = "2WFZT4HWJN.com.whetstoneapps.daymap-suite"
		guard let groupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName) else {
			return nil
		}
		
		do {
			try FileManager.default.createDirectory(at: groupContainerURL, withIntermediateDirectories: true, attributes: nil)
			return groupContainerURL
		}
		catch {
			return nil
		}
	}()
	
	static var dataStoreURL: URL? = {
		return NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("DayMap.sqlite")
	}()

	static var legacyLocalDataStoreURL: URL? = {
		#if os(iOS)
			if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
			return documentsURL.appendingPathComponent("DayMap.b_storedata")
		}
		return nil
		#else
			if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last {
			return appSupportURL.appendingPathComponent("DayMap").appendingPathComponent("DayMap.b_storedata")
		}
		return nil
		#endif
	}()
	
	static var legacyICloudDataStoreURL: URL? = {
		ensure_not_ui_thread()
		return FileManager.default.url(forUbiquityContainerIdentifier:"2WFZT4HWJN.com.whetstoneapps.daymap")?.appendingPathComponent("DayMap.b_storedata")
	}()
	
	static var historyTokenURL: URL? = {
		let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("DayMap", isDirectory: true)
		if !FileManager.default.fileExists(atPath: url.path) {
			do {
				try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
			} catch {
				log_error("Failed to create persistent container URL. Error = \(error)")
			}
		}
		return url.appendingPathComponent("historyToken.data", isDirectory: false)
	}()
}
