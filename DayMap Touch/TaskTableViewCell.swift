//
//  TaskTableViewCell.swift
//  DayMap
//
//  Created by Chad Seldomridge on 4/10/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit

protocol TaskTableViewCellDelegate: class {
	func taskTableViewCellDidChangeNameText(_ cell: TaskTableViewCell)
	func taskTableViewCellDidToggleCompletedState(_ cell: TaskTableViewCell)
}

class TaskTableViewCell: UITableViewCell, UITextFieldDelegate {
	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var completedButton: UIButton!
	weak var delegate: TaskTableViewCellDelegate?
	
	func editName() {
		nameTextField.isEnabled = true
		nameTextField.becomeFirstResponder()
		nameTextField.selectAll(self)
	}
	
	// MARK: - Private
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.isEnabled = false
		delegate?.taskTableViewCellDidChangeNameText(self)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	@IBAction func completedButtonTapped(_ sender: Any) {
		delegate?.taskTableViewCellDidToggleCompletedState(self)
	}
}
