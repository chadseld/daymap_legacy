//
//  AlertStyleRecurrenceQuestionHandler.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 6/30/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Foundation
import UIKit

class AlertStyleRecurrenceQuestionHandler: NSObject, RecurrenceQuestionHandler {
	init(recurrenceDate: Date, parentViewController: UIViewController) {
		self.recurrenceDate = recurrenceDate
		self.parentViewController = parentViewController
	}
	
	private (set) var recurrenceDate: Date
	private var parentViewController: UIViewController
	
	func shouldChangeAllOccurrences(completion: @escaping (_ answer: RecurrenceQuestionAnswer) -> Void) {
		let alert = UIAlertController(title: NSLocalizedString("This is a repeating task.", comment: "dialog"), message: NSLocalizedString("Do you want to reschedule all occurrences, or reschedule only this occurrence?", comment: "dialog"), preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "All Occurrences", style: .default, handler: { (action) in
			completion(.changeAll)
		}))
		let justThisOne = UIAlertAction(title: "Only this Occurrence", style: .default, handler: { (action) in
			completion(.changeSingleOccurrence)
		})
		alert.addAction(justThisOne)
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
			completion(.cancel)
		}))
		alert.preferredAction = justThisOne
		parentViewController.present(alert, animated: true, completion: nil)
	}
}
