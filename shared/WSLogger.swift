//
//  WSLogger.swift
//  DayMap
//
//  Created by Chad Seldomridge on 3/15/16.
//  Copyright © 2016 Whetstone Apps. All rights reserved.
//

import Foundation

#if DEBUG
func ensure_ui_thread() {
	if Thread.current.isMainThread == false {
		log_assert("This operation must be performed on the main thread.")
	}
}

func ensure_not_ui_thread() {
	if Thread.current.isMainThread == true {
		log_assert("This operation must be performed on a background thread, not the main thread.")
	}
}
#else
func ensure_ui_thread() {}
func ensure_not_ui_thread() {}
#endif

func log_debug(_ message: @autoclosure () -> String?, filePath: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
#if DEBUG
	guard let message = message() else {
		return
	}
	let fileName = (filePath as NSString).lastPathComponent
	print("DEBUG (\(fileName):\(function):\(line)): \(message)")
#endif
}

func log_info(_ message: @autoclosure () -> String?, filePath: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
	guard let message = message() else {
		return
	}
	let fileName = (filePath as NSString).lastPathComponent
	print("INFO (\(fileName):\(function):\(line)): \(message)")
}

func log_error(_ message: @autoclosure() -> String?, filePath: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
	guard let message = message() else {
		return
	}
	let fileName = (filePath as NSString).lastPathComponent
	print("ERROR (\(fileName):\(function):\(line)): \(message)")
}

func log_assert(_ message: @autoclosure() -> String?, filePath: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
	guard let message = message() else {
		return
	}
	let fileName = (filePath as NSString).lastPathComponent
	assertionFailure("ERROR (\(fileName):\(function):\(line)): \(message)")
}
