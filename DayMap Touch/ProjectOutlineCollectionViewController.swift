//
//  ProjectOutlineCollectionViewController.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 10/26/18.
//  Copyright © 2018 Whetstone Apps. All rights reserved.
//

import CoreData

class ProjectOutlineCollectionViewController: UICollectionViewController, CoreDataConsumer, UICollectionViewDelegateFlowLayout, DynamicToolbarItemProvider {

	// MARK: - CoreDataConsumer
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			loadProjects()
			collectionView?.reloadData()
			collectionView?.collectionViewLayout.invalidateLayout()
			
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
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
//		collectionView?.register(UINib.init(nibName: "ProjectCollectionViewItem", bundle: nil), forCellWithReuseIdentifier: "Project")
	}

	@objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			// TODO: get a lot smarter here about what to reload and when depending on the MOC changes
			self.loadProjects()
			self.collectionView?.reloadData()
			self.collectionView?.collectionViewLayout.invalidateLayout()
			
			// e.g. 			self.tableView.reloadData(objectsBeforeUpdate: before, objectsAfterUpdate: self.sortedProjects, managedObjectContextObjectsDidChangeNotification: notification)

		}
	}
	
	private var sortedProjects: [Project] = []
	
	private func loadProjects() {
		guard let context = coreDataContainer?.viewContext else {
			sortedProjects = []
			return
		}
		
		if let dayMap = (try? context.fetch(DayMap.primaryFetchRequest))?.last, let projects = dayMap.projects {
			sortedProjects = projects.sortedArray(using: [SortDescriptor_SortIndex, SortDescriptor_ModifiedDate]) as! [Project]
			
			log_debug("sorted projects = \(sortedProjects)")
		}
		else {
			sortedProjects = []
		}
	}

	// MARK: - Toolbar
	
	func addToolbarItems(to toolbar: UIToolbar) {
		let newProjectItem = UIBarButtonItem(title: NSLocalizedString("New Project", comment: "toolbar button"), style: .plain, target: self, action: #selector(addProject(_:)))
		var newItems = toolbar.items ?? []
		newItems.insert(newProjectItem, at: 0)
		toolbar.setItems(newItems, animated: false)
	}
	
	@IBAction func addProject(_ sender: Any) {
		guard let context = coreDataContainer?.viewContext else {
			return
		}
		
		guard let dayMap = (try? context.fetch(DayMap.primaryFetchRequest))?.last else {
			return
		}
		
		// Create a new Project
		let project = Project(context: context)
		project.sortIndex = ((sortedProjects.last?.sortIndex?.intValue ?? 0) + 1) as NSNumber
		dayMap.addToProjects(project)
		
		// Update the Table
		loadProjects()
		let insertedAtIndex = IndexPath(row: sortedProjects.count - 1, section: 0)
		collectionView?.insertItems(at: [insertedAtIndex])
		collectionView?.scrollToItem(at: insertedAtIndex, at: .right, animated: true)
		
		// Edit the new project's title
		// TODO		
//		if let cell = self.tableView.cellForRow(at: insertedAtIndex) as? ProjectTableViewCell {
//			cell.editName()
//		}
	}
	
	// MARK: -  UICollectionViewDataSource

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return sortedProjects.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Project", for: indexPath) as! ProjectCollectionViewCell
		
		cell.project = sortedProjects[indexPath.item]
//
//		switch indexPath.item {
//		case 0:
//			cell.relativePosition = .leftmost
//		case sortedProjects.count - 1:
//			cell.relativePosition = .rightmost
//		default:
//			cell.relativePosition = .center
//		}
//
//		cell.delegate = self
		
		return cell
	}
	
	// MARK: - UICollectionViewDelegateFlowLayout
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
			return CGSize(width: 0, height: 0)
		}
		let project = sortedProjects[indexPath.item]
		let width = CGFloat(widthPreference(for: project))
		
		let height = collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom - layout.sectionInset.top - layout.sectionInset.bottom
		
//			2019-03-06 16:35:14.880707-0700 DayMap Touch[8910:2552566] the item height must be less than the height of the UICollectionView minus the section insets top and bottom values, minus the content insets top and bottom values.

		return CGSize(width: width, height: height)
	}

	// MARK: - Width
	let minItemWidth = 100
	let maxItemWidth = 800
	let defaultItemWidth = 150
	
	private func widthPreferenceKey(for project: Project) -> String {
		guard let uuid = project.uuid else {
			return "OutlinePanelProjectWidth(null)"
		}
		
		return "OutlinePanelProjectWidth_" + uuid
	}
	
	func widthPreference(for project: Project?) -> Int {
		var width = defaultItemWidth
		
		if let project = project {
			let widthPreference = UserDefaults.standard.integer(forKey: widthPreferenceKey(for: project))
			if widthPreference != 0 {
				width = widthPreference
			}
		}
		
		return width
	}
	
	func saveWidthPreference(_ width: Int, for project: Project) {
		var width = width
		if width < minItemWidth {
			width = minItemWidth
		}
		if width > maxItemWidth {
			width = maxItemWidth
		}
		UserDefaults.standard.set(width, forKey: widthPreferenceKey(for: project))
	}

	
}
