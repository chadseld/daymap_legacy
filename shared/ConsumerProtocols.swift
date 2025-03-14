//
//  ConsumerProtocols.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/27/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import CoreData

protocol CoreDataConsumer: class {
	var coreDataContainer: NSPersistentContainer? { get set }
}

protocol TaskConsumer: class {
	var task: AbstractTask? { get set }
}

protocol CurrentDayConsumer: class {
	var currentDay: Date? { get set }
}
