//
//  DatabaseManager.swift
//  DayMap
//
//  Created by Chad Seldomridge on 2/5/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import CoreData

enum DatabaseManagerError: Error {
	case failedToLoadPersistentStore(error: Error?)
	case failedToSave(error: Error?)
	case failedToSetUpSyncing(error: Error?)
}

//extension Notification.Name {
//	static let ManagedObjectContextDidReset = Notification.Name("ManagedObjectContextDidReset")
//}

class DatabaseManager {
	
	private(set) var coreDataContainer: NSPersistentContainer?

	// The viewContext author name.
	// Any writing to the persistent store will generate a .NSPersistentStoreRemoteChange notification.
	// Background contexts do not use this author name, and save directly to the store, generating change notifications.
	// Changes to the store made by icloudd also write to the store and generate change notifications.
	// We use the author name to merge store changes into the viewContext, filtering out changes made by the viewContext itself.
	let appViewContextTransactionAuthorName = "DayMap"
	
	init(completionOnMain: @escaping (_ databaseManager: DatabaseManager, _ success: Bool, _ error: DatabaseManagerError?) -> Void) {
		loadLastHistoryTokenFromDisk()
		setupCoreData { (success, error) in
			if success == false {
				completionOnMain(self, false, error)
				return
			}
			
			completionOnMain(self, true, nil)
		}
	}

	func save(completionOnMain: ((_ success: Bool, _ error: DatabaseManagerError?) -> Void)?) {
		guard let coreDataContainer = coreDataContainer, coreDataContainer.persistentStoreDescriptions.isEmpty == false else {
			return
		}
		
		let context = coreDataContainer.viewContext
		context.perform {
			if context.hasChanges {
				do {
					log_debug("Saving save changes")
					try context.save()
					
					DispatchQueue.main.async {
						completionOnMain?(true, nil)
					}
				}
				catch {
					log_error("Error saving changes")
					DispatchQueue.main.async {
						completionOnMain?(false, DatabaseManagerError.failedToSave(error: error))
					}
				}
			}
			else {
				log_debug("No changes to save")
				completionOnMain?(true, nil)
			}
		}
	}
	
	// MARK: - Private
	
	private func setupCoreData(completionOnMain: @escaping (_ success: Bool, _ error: DatabaseManagerError?) -> Void) {
		// Create a container that can load CloudKit-backed stores
		let container = NSPersistentCloudKitContainer(name: "DayMap")

		// Enable history tracking and remote notifications
		guard let description = container.persistentStoreDescriptions.first else {
			fatalError("###\(#function): Failed to retrieve a persistent store description.")
		}
		let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.whetstoneapps.daymap")
		#if DEBUG
		// Set this to true, run, then set back to false to initialize the development scehma
//		cloudKitOptions.shouldInitializeSchema = true
		#endif
		description.cloudKitContainerOptions = cloudKitOptions
		description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
		description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
		
		DispatchQueue.global().async {
			let loadGroup = DispatchGroup()
			for _ in container.persistentStoreDescriptions {
				loadGroup.enter()
			}
			var loadError: Error? = nil
			container.loadPersistentStores(completionHandler: { (description, error) in
				if let error = error {
					loadError = error
				}
				loadGroup.leave()
			})
		
			loadGroup.wait()

			if let loadError = loadError {
				DispatchQueue.main.async {
					completionOnMain(false, DatabaseManagerError.failedToLoadPersistentStore(error: loadError))
				}
				return
			}
		
			container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
			container.viewContext.transactionAuthor = self.appViewContextTransactionAuthorName
			
			// Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
			container.viewContext.automaticallyMergesChangesFromParent = true
			do {
				try container.viewContext.setQueryGenerationFrom(.current)
			} catch {
				DispatchQueue.main.async {
					completionOnMain(false, DatabaseManagerError.failedToLoadPersistentStore(error: error))
				}
			}

			self.purgePersistentHistory()
			
			// Observe Core Data remote change notifications.
			NotificationCenter.default.addObserver(self, selector: #selector(self.storeRemoteChangeNotification(_:)), name: .NSPersistentStoreRemoteChange, object: container.persistentStoreCoordinator)

			DispatchQueue.main.async {
				// Clean up database
				MigrationManager().performDataCleanup(context: container.viewContext)
				self.coreDataContainer = container
				completionOnMain(true, nil)
			}
		}
	}
	
	// MARK: - Notifications
	
	// The persistent store was changed on disk. This happens when CloudKit syncs a change into our store.
	// We need to inspect the persistent history and merge changes into the viewContext.
	@objc func storeRemoteChangeNotification(_ notification: Notification) {
		log_debug("Merging changes from the other persistent store coordinator.")
		
		// Process persistent history to merge changes from other coordinators.
		historyQueue.addOperation {
			self.processPersistentHistory()
		}
	}
	
	// MARK: - Persistent history processing
	
	private lazy var historyQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		return queue
	}()
	
	/**
	Track the last history token processed for a store, and write its value to file.
	
	The historyQueue reads the token when executing operations, and updates it after processing is complete.
	*/
	private var lastHistoryToken: NSPersistentHistoryToken? = nil {
		didSet {
			saveLastHistoryTokenToDisk()
		}
	}
	
	private func loadLastHistoryTokenFromDisk() {
		if let historyTokenURL = ApplicationPaths.historyTokenURL,
			let tokenData = try? Data(contentsOf: historyTokenURL) {
			do {
				lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
			} catch {
				log_error("Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
			}
		}
	}
	
	private func saveLastHistoryTokenToDisk() {
		guard let historyTokenURL = ApplicationPaths.historyTokenURL else {
			return
		}
		
		do {
			if let token = lastHistoryToken, let tokenData = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) {
				try tokenData.write(to: historyTokenURL)
			}
			else {
				try FileManager.default.removeItem(at: historyTokenURL)
			}
		}
		catch {
			log_error("Failed to write token data. Error = \(error)")
		}

	}
	
	/**
	Process persistent history, posting any relevant transactions to the current view.
	*/
	private func processPersistentHistory() {
		guard let coreDataContainer = coreDataContainer else {
			return
		}
		let taskContext = coreDataContainer.newBackgroundContext()
		taskContext.performAndWait {
			
			// Fetch history received from outside the app since the last token
			let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
			historyFetchRequest.predicate = NSPredicate(format: "author != %@", appViewContextTransactionAuthorName)
			let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
			request.fetchRequest = historyFetchRequest
			
			let transactions: [NSPersistentHistoryTransaction]
			do {
				let historyResult = try taskContext.execute(request)
				if let historyResult = historyResult as? NSPersistentHistoryResult,
					let historyTransactions = historyResult.result as? [NSPersistentHistoryTransaction] {
					transactions = historyTransactions
				}
				else {
					transactions = []
				}
			}
			catch {
				lastHistoryToken = nil
				log_debug("Threw while fetching transaction history. Calling reset() on view context.")
				DispatchQueue.main.async {
					// This sends an NSManagedObjectContextObjectsDidChange notification with the NSInvalidatedAllObjectsKey set
					// So, we need to check for that key when listening to the notifications
					coreDataContainer.viewContext.reset()
				}
				return
			}
			
			if transactions.isEmpty {
				return
			}
			
			if transactions.count > 100 {
				// Too many transactions to process efficiently. So we reset the view context instead.
				// All managed objects are now invalid and they must be re-fetched.
				// NSFetchedResultsControllers will _not_ automatically re-fetch, so you need to manually call performFetch()
				log_debug("Transaction count \(transactions.count), calling reset() on view context.")
				DispatchQueue.main.async {
					// This sends an NSManagedObjectContextObjectsDidChange notification with the NSInvalidatedAllObjectsKey set
					// So, we need to check for that key when listening to the notifications
					coreDataContainer.viewContext.reset()
				}
			}
			else {
				// Merge the transactions into the view context.
				// This should refresh managed objects and trigger appropriate NSManagedObjectContextObjectsDidChange notifications.
				// NSFetchedResultsControllers will automatically call their delegate methods if assigned a delegate.
				transactions.forEach { transaction in
					guard let userInfo = transaction.objectIDNotification().userInfo else {
						return
					}
					NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [coreDataContainer.viewContext])
				}
			}
			
			// Update the history token using the last transaction.
			lastHistoryToken = transactions.last!.token

			let context = coreDataContainer.newBackgroundContext()
			context.performAndWait {
				MigrationManager().performDataCleanup(context: context)
				try? context.save()
			}
		}
	}
	
	private func purgePersistentHistory() {
		guard let coreDataContainer = coreDataContainer else {
			return
		}

		log_info("Purging persistent history older than 7 days")
		let sevenDaysAgo = Date(timeIntervalSinceNow: TimeInterval(exactly: -604_800)!)
		let purgeHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: sevenDaysAgo)

		do {
			try coreDataContainer.newBackgroundContext().execute(purgeHistoryRequest)
		} catch {
			log_error("Could not purge history: \(error)")
		}
	}
}
