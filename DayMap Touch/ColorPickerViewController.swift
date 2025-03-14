//
//  ColorPickerViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 4/15/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import UIKit

protocol ColorPickerViewControllerDelegate: class {
	func colorPicker(_ colorPicker: ColorPickerViewController, didPickColor color: UIColor)
}

class ColorPickerViewController: UIViewController {

	weak var delegate: ColorPickerViewControllerDelegate?
	
	var color: UIColor = UIColor.black {
		didSet {
			if let picker = colorPickerView {
				picker.color = color
			}
		}
	}
	
	// MARK: - Private
	
	@IBOutlet weak var colorPickerView: ILColorPickerView!
	
	override func viewDidLoad() {
		colorPickerView.pickerLayout = ILColorPickerViewLayoutRight
		colorPickerView.color = color
	}
	
	@IBAction func doneButtonTapped(_ sender: Any) {
		color = colorPickerView.color
		delegate?.colorPicker(self, didPickColor: self.color)
		self.dismiss(animated: true, completion: nil)
	}
}
