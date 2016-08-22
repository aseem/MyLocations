//
//  Functions.swift
//  MyLocations
//
//  Created by Aseem Kohli on 8/15/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import Foundation
import Dispatch

let applicationDocumentsDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    return paths[0]
}()

func afterDelay(seconds: Double, closure: () -> ()) {
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    dispatch_after(when, dispatch_get_main_queue(), closure)
}
