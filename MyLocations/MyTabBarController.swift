//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Aseem Kohli on 8/25/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}
