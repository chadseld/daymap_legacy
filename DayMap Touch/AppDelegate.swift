//
//  AppDelegate.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 9/6/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	private var databaseManager: DatabaseManager?
	private var saveTimer: Timer?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

		ApplicationPreferences.registerDefaults()
		window?.tintColor = UIColor.dayMapBlue

		MigrationManager().performNecessaryMigrations { (success) in
			self.databaseManager = DatabaseManager() { (databaseManager, success, error) in
				self.initializeFirstRunDatabaseState { (success, error) in
					self.finishLoadingUI()
				}
			}
		}
		
		return true
	}

	private func initializeFirstRunDatabaseState(completionOnMain: @escaping (_ success: Bool, _ error: DatabaseManagerError?) -> Void) {
		// This function sets up the initial database state on disk before we ever leach ensembles. 
		// This is the only place to create 'singleton' data entries
		
		guard let databaseManager = databaseManager else {
			completionOnMain(false, nil)
			return
		}
		
		if let coreDataContainer = databaseManager.coreDataContainer {
			DayMap.initializePrimaryDayMap(coreDataContainer: coreDataContainer)
		}
		
		// Finally, save this database state to disk before continuing
		databaseManager.save { (success, error) in
			completionOnMain(success, error)
		}
	}
	
	private func finishLoadingUI() {
		guard let coreDataContainer = databaseManager?.coreDataContainer else {
			return
		}
		
		if let consumer = self.window?.rootViewController as? CoreDataConsumer {
			consumer.coreDataContainer = coreDataContainer
		}
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
		
		log_debug("applicationWillResignActive")
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

		log_debug("applicationDidEnterBackground")
		saveTimer?.invalidate()
		
		let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
		DispatchQueue.global().async {
			self.databaseManager?.save { (success, error) in
				UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
			}
		}
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
		
		log_debug("applicationWillEnterForeground")
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		log_debug("applicationDidBecomeActive")
		initializeAutoSaveTimer()
	}

	func applicationWillTerminate(_ application: UIApplication) {
		log_debug("applicationWillTerminate")
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
	}

	func initializeAutoSaveTimer() {
		saveTimer?.invalidate()
		#if DEBUG
			let saveInterval: TimeInterval = 5
		#else
			let saveInterval: TimeInterval = 10
		#endif
		saveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true, block: { (timer) in
			self.databaseManager?.save(completionOnMain: nil)
		})
	}
}

