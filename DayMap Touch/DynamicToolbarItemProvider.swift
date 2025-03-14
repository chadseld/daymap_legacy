//
//  DynamicToolbarItemProvider.swift
//  DayMap Touch
//
//  Created by Chad Seldomridge on 5/20/19.
//  Copyright © 2019 Whetstone Apps. All rights reserved.
//

import UIKit

protocol DynamicToolbarItemProvider : UIViewController {
	func addToolbarItems(to toolbar: UIToolbar)
}
