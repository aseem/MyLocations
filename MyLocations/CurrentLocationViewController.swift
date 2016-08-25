//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Aseem Kohli on 8/2/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: NSError?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
    var timer: NSTimer?
    
    var managedObjectContext: NSManagedObjectContext!
    
    //MARK: Outlets & Actions
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    @IBAction func getLocation() {
        // get permission
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .NotDetermined {
            self.locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if (authStatus == .Denied || authStatus == .Restricted) {
            showLocationServicesDeniedAlert()
            return
        }
        
        if self.updatingLocation {
            stopLocationManager()
        }
        else {
            self.location = nil
            self.lastLocationError = nil
            self.placemark = nil
            self.lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError: \(error)")
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        self.lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations: \(newLocation)")
        
        // old reading
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        // bad reading
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location {
            distance = newLocation.distanceFromLocation(location)
        }
        
        // first reading or a more accurate reading
        if self.location == nil || self.location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            self.lastLocationError = nil
            self.location = newLocation
            updateLabels()
            
            // reading's accuracy is good enough
            if newLocation.horizontalAccuracy <= self.locationManager.desiredAccuracy {
                print("*** We're done! ***")
                stopLocationManager()
                configureGetButton()
                
                if distance > 0 {
                    self.performingReverseGeocoding = false
                }
            }
            
            // reverse-geocoding
            if !self.performingReverseGeocoding {
                print("*** Going to geocode ***")
                self.performingReverseGeocoding = true
                self.geocoder.reverseGeocodeLocation(newLocation, completionHandler: {placemarks, error in
                    print("*** Found placemarks: \(placemarks), error: \(error) ***")
                    
                    self.lastGeocodingError = error
                    if error == nil, let p = placemarks where !p.isEmpty {
                        self.placemark   = p.last!
                    }
                    else {
                        self.placemark = nil
                    }
                    
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
            else if distance < 1.0 {
                let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
                    if timeInterval > 10 {
                        print("*** Force done! ***")
                    }
                    stopLocationManager()
                    updateLabels()
                    configureGetButton()
            }
        }
    }
    
    // MARK: Location Methods
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
            self.updatingLocation = true
            self.timer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: #selector(self.didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager() {
        if self.updatingLocation {
            if let timer = self.timer {
                timer.invalidate()
            }
            self.locationManager.stopUpdatingLocation()
            self.locationManager.delegate = nil
            self.updatingLocation = false
        }
    }
    
    func didTimeOut() {
        print("*** Time out ***")
        if self.location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            updateLabels()
            configureGetButton()
        }
    }
    
    // MARK: View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
    }

    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }

    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.hidden = false
            messageLabel.text = ""
            
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
            }
            else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            }
            else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
        }
        else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.hidden = true
            
            let statusMessage: String
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
                    statusMessage = "Location Services Disabled"
                }
                else {
                    statusMessage = "Error Getting Location"
                }
            }
            else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            }
            else if updatingLocation {
                statusMessage = "Searching..."
            }
            else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
    }
    
    func configureGetButton() {
        if self.updatingLocation {
            self.getButton.setTitle("Stop", forState: .Normal)
        }
        else {
            self.getButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.coordinate = self.location!.coordinate
            controller.placemark = self.placemark
            controller.managedObjectContext = self.managedObjectContext
        }
    }
    
    // MARK: Helper Methods
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var line1 = ""
        line1.addText(placemark.subThoroughfare)
        line1.addText(placemark.thoroughfare, withSeparator: " ")
        
        var line2 = ""
        line2.addText(placemark.locality)
        line2.addText(placemark.administrativeArea, withSeparator: " ")
        line2.addText(placemark.postalCode, withSeparator: " ")
        
        line1.addText(line2, withSeparator: "\n")
        return line1
    }    
}

