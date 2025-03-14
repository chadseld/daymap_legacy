//
//  OutlineView.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 11/4/19.
//  Copyright © 2019 Whetstone Apps. All rights reserved.
//

import UIKit

protocol OutlineViewConverterDataSource: class {
	func outlineViewConverter(_ outlineView: OutlineViewConverter, numberOfChildrenOfItem item: Any?) -> Int
	func outlineViewConverter(_ outlineView: OutlineViewConverter, child index: Int, ofItem item: Any?) -> Any
//	func outlineViewConverter(_ outlineView: OutlineViewConverter, objectValueItem item: Any?) -> Any?
	func outlineViewConverter(_ outlineView: OutlineViewConverter, viewFor item: Any, indentation: Int) -> UITableViewCell?
	// TODO - isItemExpandable
	// expanded state, etc..
	// drag drop
}

class OutlineViewConverter : NSObject, UITableViewDataSource {
	weak var dataSource: OutlineViewConverterDataSource?
	
	func reloadData(for tableView: UITableView) {
		reloadData()
		tableView.reloadData()
	}
	
	// MARK: - UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rootItems.count // TODO just assuming collapsed right now
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// TODO just assuming collapsed right now
		let cell = dataSource?.outlineViewConverter(self, viewFor: rootItems[indexPath.row].value, indentation: 0)
		return cell ?? UITableViewCell()
	}
	
	// MARK: - Private
	
	/// build tree, structure, starting at a single root,
	
	private var rootItems: [Item] = []
	
	private func reloadData() {
		rootItems = fetchChildValues(of: nil).map({ (value) -> Item in
			let item = Item()
			item.value = value
			return item
		})
		
		loadChildTree(of: rootItems)
	}
	
	class Item {
		var value: Any?
		var children: [Item] = []
	}
	
	private func loadChildTree(of items: [Item]) {
		for item in items {
			item.children = fetchChildValues(of: item).map({ (value) -> Item in
				let item = Item()
				item.value = value
				return item
			})
			loadChildTree(of: item.children)
		}
	}
	
	private func fetchChildValues(of item: Item?) -> [Any?] {
		guard let dataSource = dataSource else {
			return []
		}
		
		let numberOfChildren = dataSource.outlineViewConverter(self, numberOfChildrenOfItem: item?.value)
		var childValues: [Any?] = []
		for index in 0 ..< numberOfChildren {
			childValues.append(dataSource.outlineViewConverter(self, child: index, ofItem: item?.value))
		}
		return childValues;
	}
}
