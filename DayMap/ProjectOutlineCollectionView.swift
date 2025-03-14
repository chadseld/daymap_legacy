//
//  ProjectOutlineCollectionView.swift
//  DayMap
//
//  Created by Chad Seldomridge on 11/18/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

import Cocoa

protocol ProjectOutlineCollectionViewDelegate {
	func collectionView(_ collectionView: NSCollectionView, widthDraggingRegionForItemAt indexPath: IndexPath) -> NSRect?
	func collectionView(_ collectionView: NSCollectionView, widthOfItemAt indexPath: IndexPath) -> CGFloat
	func collectionView(_ collectionView: NSCollectionView, didDragWidthOfItemAt indexPath: IndexPath, to width: CGFloat)
}

class ProjectOutlineCollectionView: NSCollectionView {
	
	override func draw(_ dirtyRect: NSRect) {
		NSColor(calibratedWhite: 0.90, alpha: 1).set()
		__NSRectFill(dirtyRect)
	}

	override var frame: NSRect {
		didSet {
			invalidateWidthDragRegions()
		}
	}
	
	override func reloadData() {
		super.reloadData()
		invalidateWidthDragRegions()
	}
	
	override func reloadSections(_ sections: IndexSet) {
		super.reloadSections(sections)
		invalidateWidthDragRegions()
	}
	
	override func reloadItems(at indexPaths: Set<IndexPath>) {
		super.reloadItems(at: indexPaths)
		invalidateWidthDragRegions()
	}
	
	private var widthDraggingRegions: [(NSRect, IndexPath)] = []

	private func invalidateWidthDragRegions() {
		widthDraggingRegions = []
		
		guard let dataSource = dataSource, let delegate = delegate as? ProjectOutlineCollectionViewDelegate else {
			return
		}
		
		for section in 0 ..< (dataSource.numberOfSections?(in: self) ?? 1) {
			for item in 0 ..< dataSource.collectionView(self, numberOfItemsInSection: section) {
				let indexPath = IndexPath(item: item, section: section)
				if let widthDraggingRegion = delegate.collectionView(self, widthDraggingRegionForItemAt: indexPath) {
					widthDraggingRegions.append((widthDraggingRegion, indexPath))
				}
			}
		}

		self.window?.invalidateCursorRects(for: self)
	}
	
	// Add cursor rects for each drag handle region
	override func resetCursorRects() {
		super.resetCursorRects()
		widthDraggingRegions.forEach { addCursorRect($0.0, cursor: .resizeLeftRight) }
	}
	
	// If mouse is in drag separator region, return self so that the mouse messages don't get passed to subviews
	override func hitTest(_ point: NSPoint) -> NSView? {
		let localPoint = convert(point, from: superview)
		
		for (region, _) in widthDraggingRegions {
			if NSMouseInRect(localPoint, region, isFlipped) {
				return self
			}
		}
		
		return super.hitTest(point)
	}
	
	private struct WidthDraggingInfo {
		let regionRect: NSRect
		let itemIndexPath: IndexPath
		let startingPoint: NSPoint
		let startingWidth: CGFloat
	}
	private var currentWidthDrag: WidthDraggingInfo?
	
	// If mouse is in drag separator region, take over drag, otherwies let super handle it.
	override func mouseDown(with event: NSEvent) {
		if let delegate = delegate as? ProjectOutlineCollectionViewDelegate {
			let location = convert(event.locationInWindow, from: nil)
			for (region, indexPath) in widthDraggingRegions {
				if NSMouseInRect(location, region, isFlipped) {
					currentWidthDrag = WidthDraggingInfo(regionRect: region, itemIndexPath: indexPath, startingPoint: location, startingWidth: delegate.collectionView(self, widthOfItemAt: indexPath))
					return
				}
			}
		}

		currentWidthDrag = nil
		super.mouseDown(with: event)
	}
	
	override func mouseUp(with event: NSEvent) {
		if let _ = currentWidthDrag {
			currentWidthDrag = nil
			invalidateWidthDragRegions()
			return
		}
		
		super.mouseUp(with: event)
	}
	
	// If we are tracking a mouse drag in a separator region, pass messages up to delegate to that effect
	override func mouseDragged(with event: NSEvent) {
		if let currentWidthDrag = currentWidthDrag {
			let location = convert(event.locationInWindow, from: nil)
			if let delegate = delegate as? ProjectOutlineCollectionViewDelegate {
				delegate.collectionView(self, didDragWidthOfItemAt: currentWidthDrag.itemIndexPath, to: currentWidthDrag.startingWidth + (location.x - currentWidthDrag.startingPoint.x))
			}
		}
		else {
			super.mouseDragged(with: event)
		}
	}
	
}
