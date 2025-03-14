//
//  ProjectOutlineCollectionViewController.swift
//  DayMap
//
//  Created by Chad Seldomridge on 10/8/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

class ProjectOutlineCollectionViewController: NSViewController, CoreDataConsumer, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, ProjectCollectionViewItemDelegate, ProjectOutlineCollectionViewDelegate {
	
	// MARK: - CoreDataConsumer
	
	var coreDataContainer: NSPersistentContainer? = nil {
		didSet {
			loadProjects()
			
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
	
	// MARK: - Private
	
	@IBOutlet weak var collectionView: NSCollectionView!
	

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let consumer = segue.destinationController as? CoreDataConsumer {
            consumer.coreDataContainer = coreDataContainer
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		collectionView.register(NSNib(nibNamed: "ProjectCollectionViewItem", bundle: nil), forItemWithIdentifier: NSUserInterfaceItemIdentifier("Project"))
    }
    
    @objc func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
        DispatchQueue.main.async {
			// TODO: get a lot smarter here about what to reload and when depending on the MOC changes
            self.loadProjects()
        }
    }
    
    
	private var sortedProjects: [Project] = [] {
		didSet {
			collectionView.reloadData()
			collectionView.collectionViewLayout?.invalidateLayout()
		}
	}

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
	
	// MARK: -  NSCollectionViewDataSource
	
	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return sortedProjects.count
	}
	
	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("Project"), for: indexPath) as! ProjectCollectionViewItem
		
		item.project = sortedProjects[indexPath.item]
		
		switch indexPath.item {
		case 0:
			item.relativePosition = .leftmost
		case sortedProjects.count - 1:
			item.relativePosition = .rightmost
		default:
			item.relativePosition = .center
		}
		
		item.delegate = self
		
		return item
	}
	
	// MARK: - NSCollectionViewDelegateFlowLayout
	
	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
		let project = sortedProjects[indexPath.item]
		let width = CGFloat(widthPreference(for: project))
		
		return NSSize(width: width, height: collectionView.enclosingScrollView?.contentSize.height ?? 0)
	}
	
	// MARK: - ProjectOutlineCollectionViewDelegate
	
	func collectionView(_ collectionView: NSCollectionView, widthOfItemAt indexPath: IndexPath) -> CGFloat {
		let project = sortedProjects[indexPath.item]
		let width = CGFloat(widthPreference(for: project))
		return width
	}

	func collectionView(_ collectionView: NSCollectionView, widthDraggingRegionForItemAt indexPath: IndexPath) -> NSRect? {
		let dragSectionOverlap: CGFloat = 2
		let spacing = (collectionView.collectionViewLayout as? NSCollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0

		let itemRect = collectionView.frameForItem(at: indexPath.item)

		return NSMakeRect(NSMaxX(itemRect) - dragSectionOverlap, NSMinY(itemRect), dragSectionOverlap * 2 + spacing, NSHeight(itemRect))
	}
	
	func collectionView(_ collectionView: NSCollectionView, didDragWidthOfItemAt indexPath: IndexPath, to width: CGFloat) {
		guard indexPath.item >= 0, indexPath.item < sortedProjects.count else {
			return
		}
		
		let project = sortedProjects[indexPath.item]
		
		saveWidthPreference(Int(width), for: project)
		
		//		let indexPath = collectionView.indexPath(for: item)
		//		let originalAttributes = collectionView.collectionViewLayout?.layoutAttributesForItem(at: indexPath)
		//		let newAttributes = originalAttributes.copy()
		//		newAttributes.size.width = width
		//		let context = collectionView.collectionViewLayout?.invalidationContext(forPreferredLayoutAttributes: newAttributes, withOriginalAttributes: originalAttributes)
		//		collectionView.collectionViewLayout?.invalidateLayout(with: context)
		collectionView.collectionViewLayout?.invalidateLayout()
	}
}
