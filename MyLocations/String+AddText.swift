//
//  String+AddText.swift
//  MyLocations
//
//  Created by Aseem Kohli on 8/25/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import Foundation

extension String {
    mutating func addText(text: String?, withSeparator separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}
