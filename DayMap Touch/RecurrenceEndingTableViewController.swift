//
//  RecurrenceEndingTableViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 5/5/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit
import CoreData

protocol RecurrenceEndingTableViewControllerDelegate: class {
	func recurrenceEndingTableViewControllerDidChange(_ controller: RecurrenceEndingTableViewController)
}
class RecurrenceEndingTableViewController: UITableViewController {
	weak var delegate: RecurrenceEndingTableViewControllerDelegate?
	
	var endAfterDate: Date? {
		didSet {
			if self.isViewLoaded {
				updateControls()
				self.tableView.reloadData()
			}
		}
	}
	var endAfterCount: Int? {
		didSet {
			if self.isViewLoaded {
				updateControls()
				self.tableView.reloadData()
			}
		}
	}
	
	// MARK: - Private
	
	@IBOutlet weak var typeCell: UITableViewCell!
	@IBOutlet weak var dateCell: UITableViewCell!
	@IBOutlet weak var timesCell: UITableViewCell!
	@IBOutlet weak var neverCell: UITableViewCell!
	@IBOutlet weak var typeSegmentedControl: UISegmentedControl!
	@IBOutlet weak var datePicker: UIDatePicker!
	@IBOutlet weak var timesTextField: UITextField!
	@IBOutlet weak var timesStepper: UIStepper!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		datePicker.timeZone = TimeZone(abbreviation: "GMT")!
		
		updateControls()
		self.tableView.reloadData()
	}
	
	func updateControls() {
		if let _ = endAfterDate {
			typeSegmentedControl.selectedSegmentIndex = 0
		}
		else if let _ = endAfterCount {
			typeSegmentedControl.selectedSegmentIndex = 1
		}
		else {
			typeSegmentedControl.selectedSegmentIndex = 2
		}
		
		datePicker.date = endAfterDate ?? Date.today
		timesStepper.value = Double(endAfterCount ?? 1)
		if self.timesTextField.isFirstResponder == false {
			self.timesTextField.text = NSString(format: "%ld", endAfterCount ?? 1) as String
		}
	}
	
	@IBAction func endTypeSegmentedControlChanged(_ sender: Any) {
		if typeSegmentedControl.selectedSegmentIndex == 0 {
			endAfterCount = nil
			if endAfterDate == nil {
				endAfterDate = Date.today
			}
		}
		else if typeSegmentedControl.selectedSegmentIndex == 1 {
			endAfterDate = nil
			if endAfterCount == nil {
				endAfterCount = 3
			}
		}
		else {
			endAfterDate = nil
			endAfterCount = nil
		}
		updateControls()
		self.tableView.reloadData()
		delegate?.recurrenceEndingTableViewControllerDidChange(self)
	}
	
	@IBAction func dateChanged(_ sender: Any) {
		endAfterDate = datePicker.date
		delegate?.recurrenceEndingTableViewControllerDidChange(self)
	}
	
	@IBAction func timesStepperChanged(_ sender: Any) {
		self.timesTextField.endEditing(false)
		endAfterCount = Int(timesStepper.value)
		delegate?.recurrenceEndingTableViewControllerDidChange(self)
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		var count = ((timesTextField.text ?? "") as NSString).integerValue
		if count <= 0 {
			count = 1
		}
		endAfterCount = count
		delegate?.recurrenceEndingTableViewControllerDidChange(self)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	// MARK: - Table View
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if endAfterDate == nil && indexPath.row == 1 {
			return super.tableView(tableView, heightForRowAt: IndexPath(row: 2, section: 0))
		}
		return super.tableView(tableView, heightForRowAt: indexPath)
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 0 {
			return typeCell
		}
		else {
			if let _ = endAfterDate {
				return dateCell
			}
			else if let _ = endAfterCount {
				return timesCell
			}
			else {
				return neverCell
			}
		}
	}
}
