//
//  Location.swift
//  MyLocations
//
//  Created by Aseem Kohli on 8/15/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Location: NSManagedObject, MKAnnotation {

    // MARK: - MKAnnotation Protocol
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    var title: String? {
        if locationDescription.isEmpty {
            return "(No Description)"
        }
        else {
            return locationDescription
        }
    }
    
    var subtitle: String? {
        return category
    }

}
