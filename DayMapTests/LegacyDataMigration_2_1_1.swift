//
//  LegacyDataMigration_2_1_1.swift
//  DayMap
//
//  Created by Chad Seldomridge on 10/13/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import XCTest
@testable import DayMap

class LegacyDataMigration_2_1_1: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		// Copy legacy data into known location
		guard let legacyLocation = ApplicationPaths.legacyLocalDataStoreURL else {
			return
		}
		
		do {
			let haveLegacyData = FileManager.default.fileExists(atPath: legacyLocation.path)
			
			if haveLegacyData {
				// Move it asside
				let previousDataLocation = legacyLocation.appendingPathExtension("previous")
				if FileManager.default.fileExists(atPath: previousDataLocation.path) {
					XCTFail("Could not move asside previous data")
					return
				}
				else {
					try FileManager.default.moveItem(at: legacyLocation, to: previousDataLocation)
				}
			}
			
			// Copy
			let bundle = Bundle(for: LegacyDataMigration_2_1_1.self)
			let legacyDataURL = bundle.url(forResource: "Demo Data 2.1.1 DayMap", withExtension: "b_storedata")
			
			try FileManager.default.copyItem(at: legacyDataURL!, to: legacyLocation)
		} catch {
			XCTFail("Could not set up test data")
		}
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		if let legacyLocation = ApplicationPaths.legacyLocalDataStoreURL, let previousDataLocation = ApplicationPaths.legacyLocalDataStoreURL?.appendingPathExtension("previous") {
			if FileManager.default.fileExists(atPath: previousDataLocation.path) {
				try? FileManager.default.removeItem(at: legacyLocation)
				try? FileManager.default.moveItem(at: previousDataLocation, to: legacyLocation)
			}
		}
		// if moved legacy data asside, move it back
        super.tearDown()
    }

    func testMigration() {
		let migrationExpectation = self.expectation(description: "migration")
		
		MigrationManager().performNecessaryMigrations { (success) in
			XCTAssert(success)
			let _ = DatabaseManager { (databaseManager, success, error) -> Void in
				XCTAssert(success)
				
				guard let viewContext = databaseManager.coreDataContainer?.viewContext else {
					XCTFail()
					return
				}
				
				do {
					let projects = try viewContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Project"))
					XCTAssert(projects.count == 10)
					
					let tasks = try viewContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Task"))
					XCTAssert(tasks.count == 32)
					
					log_info("\(projects.count) Projects, \(tasks.count) Tasks")

				} catch {
					XCTFail()
				}
				
				migrationExpectation.fulfill()
			}
		}

		self.waitForExpectations(timeout: 10) { (error) in
			XCTAssertNil(error, "Error")
		}
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
