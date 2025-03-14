//
//  SheetStyleRecurrenceQuestionHandler.swift
//  DayMap
//
//  Created by Chad Seldomridge on 1/16/18.
//  Copyright © 2018 Whetstone Apps. All rights reserved.
//

import Cocoa

class SheetStyleRecurrenceQuestionHandler: NSObject, RecurrenceQuestionHandler {
	
	init(recurrenceDate: Date, parentViewController: NSViewController) {
		self.recurrenceDate = recurrenceDate
		self.parentViewController = parentViewController
	}

	private (set) var recurrenceDate: Date
	private var parentViewController: NSViewController

	func shouldChangeAllOccurrences(completion: @escaping (RecurrenceQuestionAnswer) -> Void) {
		let alert = NSAlert()
		alert.messageText = NSLocalizedString("This is a repeating task.", comment: "alert question")
		alert.informativeText = NSLocalizedString("Do you want to reschedule all occurrences, or reschedule only this occurrence?", comment: "alert question")
		alert.addButton(withTitle: NSLocalizedString("All Occurrences", comment: "button"))
		alert.addButton(withTitle: NSLocalizedString("Only this Occurrence", comment: "button"))
		alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "button"))
		
		let handleResponse: (_: NSApplication.ModalResponse) -> Void = { response in
			switch response {
			case .alertFirstButtonReturn:
				completion(.changeAll)
			case .alertSecondButtonReturn:
				completion(.changeSingleOccurrence)
			default:
				completion(.cancel)
			}
		}
	
		if let window = parentViewController.view.window {
			alert.beginSheetModal(for: window) { (response) in
				handleResponse(response)
			}
		}
		else {
			let response = alert.runModal()
			handleResponse(response)
		}
	}
}
