//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Aseem Kohli on 8/2/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: NSError?
    
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
        }
    }
    
    func stopLocationManager() {
        if self.updatingLocation {
            self.locationManager.stopUpdatingLocation()
            self.locationManager.delegate = nil
            self.updatingLocation = false
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
}

