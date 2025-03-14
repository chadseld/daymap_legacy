//
//  ProjectCollectionViewItem.swift
//  DayMap
//
//  Created by Chad Seldomridge on 10/29/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

protocol ProjectCollectionViewItemDelegate: class {

}

class ProjectCollectionViewItem: NSCollectionViewItem, NSOutlineViewDelegate, NSOutlineViewDataSource, CoreDataConsumer {

	weak var delegate: ProjectCollectionViewItemDelegate?
	
	// MARK: - CoreDataConsumer
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			outlineView.reloadData()
			
			self.children.forEach { (controller) in
				if let consumer = controller as? CoreDataConsumer {
					consumer.coreDataContainer = coreDataContainer
				}
			}
			
			// Notification for MOC changes
			NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: oldValue?.viewContext)
			NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChangeNotification(_:)), name: .NSManagedObjectContextObjectsDidChange,
												   object: coreDataContainer?.viewContext)
		}
	}
	
	@objc dynamic var project: Project? {
		didSet {
			outlineView.reloadData()
			headerView.color = project?.nativeColor ?? .dayMapBlue
		}
	}
	
	enum RelativePosition {
		case leftmost
		case center
		case rightmost
	}
	
	var relativePosition: RelativePosition = .center {
		didSet {
			// Customize drawing behavior depending on if first, last, or middle
//			switch relativePosition {
//			case .leftmost:
//			case .center:
//			case .rightmost:
//			}
		}
	}
	
	// Implementation notes:
	// Cell classes should not use much binding directly to the Task object
	// (a little binding is ok), because tearing down and setting up the binding is expensive
	//
	// Register for MOC changes here and if an item changes that we are presenting,
	// reload the affected cell(s)
	// Don't put the change notification onus on the cells. Handle all that here at the project level.
	
	
	
	
	// MARK: - Private
	
	@IBOutlet weak var outlineView: NSOutlineView!
	@IBOutlet weak var headerView: ProjectHeaderView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
			
		NotificationCenter.default.addObserver(self, selector: #selector(selectionManagerDidChangeSelectionNotification(_:)), name: .SelectionManagerDidChangeSelection, object: nil)
    }

	@objc func selectionManagerDidChangeSelectionNotification(_ notification: Notification) {
		guard let sender = notification.userInfo?["sender"] as AnyObject?, sender !== self else { // ignore notifications that originate from us
			return
		}
		
		// TODO: - Update selection
	}
	
	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			// TODO: - this
		}
	}
	
	func editSelectedTask(_ sender: AnyObject) {
		let selectedRows = outlineView.selectedRowIndexes
		
		guard let row = selectedRows.first,
			let task = outlineView.item(atRow: row) as? Task,
			let cellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: true) else {
			return
		}
		
		let popover = NSPopover()
		popover.appearance = NSAppearance(named: .vibrantLight)
		popover.behavior = .semitransient
		popover.animates = true
		
//		TaskEditPopoverViewController *viewController = [TaskEditPopoverViewController taskEditPopoverViewController];
//		viewController.popover = popover;
//		viewController.shownForDay = self.day;
//		viewController.task = self.task;
//		popover.contentViewController = viewController;
//		popover.delegate = viewController;
		
		let editController = TaskEditPopoverViewController()
		editController.currentDay = nil
		editController.task = task
		popover.contentViewController = editController
		
		// We show popover relative to the document view because background data changes may cause the outline view to reload the cell views, which will immeditaely close the popover.
		if let hostView = outlineView.enclosingScrollView?.documentView {
			popover.show(relativeTo: hostView.convert(cellView.bounds, from: cellView), of: hostView, preferredEdge: .maxX)
		}
	}

	// MARK: - Outline View
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if item == nil {
			return project?.children?.count ?? 0
		}
		
		if let task = item as? AbstractTask {
			return task.children?.count ?? 0
		}
		
		return 0
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		if item == nil {
			return (project!.children!.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [Task])[index]
		}
		
		if let task = item as? AbstractTask {
			return (task.children!.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [Task])[index]
		}
			
		return "Error"
	}

	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		if let task = item as? AbstractTask {
			return (task.children?.count ?? 0) > 0
		}
		return false
	}

	func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
		return item
	}
	
	func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
		let rowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("RowView"), owner: nil) as? NSTableRowView
		rowView?.draggingDestinationFeedbackStyle = .gap
		return rowView
	}
	
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: nil)
	}
	
	// MARK: - Actions
	
	@IBAction func outlineViewAction(_ sender: Any) {
		// This action is called whenever a mouse is clicked anywhere in the outline view. Either a row was clicked, or
		// the area under the rows was clicked. If the area under the rows was clicked, we notify the selection manager
		// to clear the selection. This is because the current selection may be in a different outline view elsewhere
		// in the app, (in that case our outline view delegate selection changed method won't fire), and we still need to clear the selection.
		if outlineView.selectedRowIndexes.isEmpty {
			SelectionManager.shared.clearSelection(sender: self)
		}
	}
	
	@IBAction func outlineViewDoubleAction(_ sender: Any) {
		if outlineView.selectedRowIndexes.isEmpty {
			// TODO: - add task
		}
		else {
			// TODO: - select and edit clicked task
			editSelectedTask(self)
		}
	}
}
