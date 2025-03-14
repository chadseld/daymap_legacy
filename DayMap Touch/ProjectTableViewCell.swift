//
//  ProjectTableViewCell.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/29/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit

protocol ProjectTableViewCellDelegate: class {
	func projectTableViewCellDidChangeNameText(_ cell: ProjectTableViewCell)
}

class ProjectTableViewCell: UITableViewCell, UITextFieldDelegate {
	@IBOutlet weak var nameTextField: UITextField!
	var projectColor: UIColor = UIColor.white {
		didSet {
			colorView.backgroundColor = projectColor
		}
	}
	weak var delegate: ProjectTableViewCellDelegate?
	
	func editName() {
		nameTextField.isEnabled = true
		nameTextField.becomeFirstResponder()
		nameTextField.selectAll(self)
	}
	
	// MARK: - Private
	@IBOutlet private weak var colorView: UIView!
	
	override func awakeFromNib() {
		colorView.layer.cornerRadius = 5
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.isEnabled = false
		delegate?.projectTableViewCellDidChangeNameText(self)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	override func setHighlighted(_ highlighted: Bool, animated: Bool) {
		super.setHighlighted(highlighted, animated: animated)
		// UITableViewCell changes the background color of all sub views when cell is selected or highlighted
		colorView.backgroundColor = projectColor
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		// UITableViewCell changes the background color of all sub views when cell is selected or highlighted 
		colorView.backgroundColor = projectColor
	}
}
