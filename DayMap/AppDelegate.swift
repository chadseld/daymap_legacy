//
//  AppDelegate.swift
//  DayMap
//
//  Created by Chad Seldomridge on 2/5/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	private var databaseManager: DatabaseManager?
    private var mainWindowController: MainWindowController?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		#if DEBUG
		if IsOptionKeyPressed() && IsCommandKeyPressed() {
			let alert = NSAlert()
			alert.messageText = "Delete all CloudKit Data?"
			alert.informativeText = "This can not be undone."
			alert.addButton(withTitle: "Cancel")
			alert.addButton(withTitle: "Delete Data")
			if alert.runModal() == .alertSecondButtonReturn {
				DeleteCloudKitData(zoneName: "com.apple.coredata.cloudkit.zone", containerIdentifier: "iCloud.com.whetstoneapps.daymap")
				if let historyTokenURL = ApplicationPaths.historyTokenURL {
					try? FileManager.default.removeItem(at: historyTokenURL)
				}
				return
			}
		}
		#endif
		
		ApplicationPreferences.registerDefaults()
		
		MigrationManager().performNecessaryMigrations { (success) in
			self.databaseManager = DatabaseManager() { (databaseManager, success, error) in
				self.initializeFirstRunDatabaseState { (success, error) in
					self.finishLoadingUI()
				}
			}
		}
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

        let storyboard = NSStoryboard(name: "MainWindow", bundle: nil)
        mainWindowController = storyboard.instantiateInitialController() as? MainWindowController
        mainWindowController?.coreDataContainer = coreDataContainer
        mainWindowController?.showWindow(self)
    }


	func applicationWillTerminate(_ aNotification: Notification) {
		
	}

	// MARK: - Core Data Saving and Undo support

	@IBAction func saveAction(_ sender: AnyObject!) {
	    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
	    if false == databaseManager?.coreDataContainer?.viewContext.commitEditing() {
	        log_error("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
	    }
		databaseManager?.save(completionOnMain: { (success, error) in
			if false == success {
				//				TODO: show save error
				//				let nserror = error as NSError
				//	            NSApplication.sharedApplication().presentError(nserror)
			}
		})
	}

	func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
	    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
	    return databaseManager?.coreDataContainer?.viewContext.undoManager
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		UserDefaults.standard.synchronize()

	    // Save changes in the application's managed object context before the application terminates.
		guard let _ = databaseManager else {
			return .terminateNow
		}
		
	    if false == databaseManager?.coreDataContainer?.viewContext.commitEditing() {
	        log_error("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
	        return .terminateCancel
	    }

		databaseManager?.save(completionOnMain: { (success, error) in
			if false == success {
				// TODO: show save error
			}
			NSApp.reply(toApplicationShouldTerminate: success)
		})
		return .terminateLater
		
//		let sem = dispatch_semaphore_create(0);
//		var saveSuccess = false
//		databaseManager?.saveDataWithCompletionOnMain({ (success, error) -> Void in
//			saveSuccess = success
//			dispatch_semaphore_signal(sem)
//		})
//		let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC))
//		dispatch_semaphore_wait(sem, timeout);
//
//		if false == saveSuccess {
//			// TODO: show save error
//			return .TerminateCancel
//		}
//		
//		return .TerminateNow
//
//		
//	    if !databaseManager?.mainManagedObjectContext.hasChanges {
//	        return .TerminateNow
//	    }
//	    
//	    do {
//	        try databaseManager?.mainManagedObjectContext.save()
//	    } catch {
//	        let nserror = error as NSError
//	        // Customize this code block to include application-specific recovery steps.
//	        let result = sender.presentError(nserror)
//	        if (result) {
//	            return .TerminateCancel
//	        }
//	        
//	        let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
//	        let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
//	        let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
//	        let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
//	        let alert = NSAlert()
//	        alert.messageText = question
//	        alert.informativeText = info
//	        alert.addButtonWithTitle(quitButton)
//	        alert.addButtonWithTitle(cancelButton)
//	        
//	        let answer = alert.runModal()
//	        if answer == NSAlertFirstButtonReturn {
//	            return .TerminateCancel
//	        }
//	    }
//	    // If we got here, it is time to quit.
//	    return .TerminateNow
	}

}

