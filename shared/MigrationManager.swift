//
//  MigrationManager.swift
//  DayMap
//
//  Created by Chad Seldomridge on 7/3/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import CoreData

class MigrationManager: NSObject {
	func performNecessaryMigrations(completionOnMain: @escaping (_ success: Bool) -> Void) {
		migrateLegacyDayMap2Data { (success) in
			// Future migrations go here...
			// Note: Automatic Core Data migrations do not follow v1->v2->v3, they go stright from v1->v3. To progress one version at a time, you must 
			// implement incremental migrations yourself.
			//
			completionOnMain(success)
		}
	}
	
	func performDataCleanup(context: NSManagedObjectContext) {
		DayMap.deduplicatePrimaryDayMaps(context: context)
	}

	// MARK: - Private Migrations
	
	/**
	 * This migrates DayMap 2.11 data in the old Data location to DayMap 3.0 data in the new data location.
	 */
	private func migrateLegacyDayMap2Data(completionOnMain: @escaping (_ success: Bool) -> Void) {
		DispatchQueue.global().async {
			let shouldMigrate = self.shouldMigrateLegacyDayMap2Data()
			
			if shouldMigrate {
				log_info("Migrating from legacy data location...")
				
				guard let modernLocation = ApplicationPaths.dataStoreURL, let legacyLocation = self.resolvedLegacyLocation() else {
					log_error("Modern or Legacy URL is nil. Can not run migrations.")
					return
				}
				
				guard let dataModelURL = Bundle.main.url(forResource: "DayMap", withExtension: "momd"),
                    let mom = NSManagedObjectModel(contentsOf: dataModelURL) else {
					DispatchQueue.main.async {
						log_error("Failed to load managed object model.")
						completionOnMain(false)
					}
					return
				}
				
				let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
				
				defer {
					for store in psc.persistentStores {
						do {
							try psc.remove(store)
						}
						catch {
							// Ignore error here
						}
					}
				}
				
				let options = [NSMigratePersistentStoresAutomaticallyOption : true,
				               NSInferMappingModelAutomaticallyOption : true]
				
				do {
					let binaryStore = try psc.addPersistentStore(ofType: NSBinaryStoreType, configurationName: nil, at: legacyLocation, options: options)
					let _ = try psc.migratePersistentStore(binaryStore, to: modernLocation, options: options, withType: NSSQLiteStoreType)
				}
				catch {
					DispatchQueue.main.async {
						log_error("Failed to load and migrate legacy store.")
						completionOnMain(false)
					}
					return
				}
				
				log_info("Done.")
			}

			DispatchQueue.main.async {
				completionOnMain(true)
			}
		}
	}
	
	// MARK: - Private

	private func forceSyncOfUbiquitousFile(url: URL) {
		do {
			if let downloadingStatus = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]).ubiquitousItemDownloadingStatus {
				if downloadingStatus == .current { // exists, and is current
					return
				}
				else if downloadingStatus == .downloaded { // downloaded, but stale
					
				}
				else if downloadingStatus == .notDownloaded {
					
				}
			}
			else {
				// file does not exist, or it does exist and have no metadata yet
				// or the resource is not available
			}
		} catch {
			return
		}
		
		do {
			try FileManager.default.startDownloadingUbiquitousItem(at: url)
			
			// wait until the file is finished downloading here
			var downloadingStatus = URLUbiquitousItemDownloadingStatus.notDownloaded
			let startTime = Date.timeIntervalSinceReferenceDate
			repeat {
				if let status = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]).ubiquitousItemDownloadingStatus {
					downloadingStatus = status
				}
			} while(downloadingStatus != .current && (Date.timeIntervalSinceReferenceDate - startTime) < 20)
			
			if downloadingStatus == .current {
				return
			}
			else {
				return // timed out
			}
		} catch {
			// our URL was bad, or there is no file on iCloud to download -- file really does not exist
			return
		}
	}
	
	private func resolvedLegacyLocation() -> URL? {
		// Check for legacy data
		let legacyLocationOptional: URL?
		if ApplicationPreferences.legacyICloudEnabled {
			legacyLocationOptional = ApplicationPaths.legacyICloudDataStoreURL
			if let url = legacyLocationOptional {
				self.forceSyncOfUbiquitousFile(url: url) // this can take some time
			}
		}
		else {
			legacyLocationOptional = ApplicationPaths.legacyLocalDataStoreURL
		}
		
		return legacyLocationOptional
	}
	
	private func shouldMigrateLegacyDayMap2Data() -> Bool {
		// Check for modern data first. It is local (not in iCloud, and can be checked for quickly)
		guard let modernLocation = ApplicationPaths.dataStoreURL else {
			log_error("Modern data URL is nil. Can not run migrations.")
			return false
		}
		
		let haveModernData = FileManager.default.fileExists(atPath: modernLocation.path)
		if haveModernData { // no need to migrate. Bail early to avoid downloading legacy data from iCloud.
			return false
		}
		
		// Check to see if we should migrate or are already at the latest version
		guard let legacyLocation = resolvedLegacyLocation() else {
			log_error("Legacy data URL is nil. Can not run migrations.")
			return false
		}
		
		let haveLegacyData = FileManager.default.fileExists(atPath: legacyLocation.path)
		let shouldMigrate = haveLegacyData && false == haveModernData
		return shouldMigrate;
	}
}
