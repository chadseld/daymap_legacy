//
//  RecurrenceFrequencyTableViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 5/5/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

protocol RecurrenceFrequencyTableViewControllerDelegate: class {
	func recurrenceFrequencyTableViewControllerDidChangeFrequency(_ controller: RecurrenceFrequencyTableViewController, frequency: RecurrenceFrequency)
}

class RecurrenceFrequencyTableViewController: UITableViewController {
	weak var delegate: RecurrenceFrequencyTableViewControllerDelegate?
	
	var frequency: RecurrenceFrequency = .daily {
		didSet {
			for row in 0 ..< self.tableView.numberOfRows(inSection: 0) {
				if let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0)) {
					cell.accessoryType = (cell.tag == frequency.rawValue) ? .checkmark : .none
				}
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedRow = self.tableView.indexPathForSelectedRow?.row ?? 0
		if let cell = self.tableView.cellForRow(at: IndexPath(row: selectedRow, section: 0)) {
			if let frequency = RecurrenceFrequency(rawValue: cell.tag) {
				self.frequency = frequency
				
				delegate?.recurrenceFrequencyTableViewControllerDidChangeFrequency(self, frequency: frequency)
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
}
