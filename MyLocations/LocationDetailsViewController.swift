//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Aseem Kohli on 8/3/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

private let dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .ShortStyle
    return formatter
}()

class LocationDetailsViewController: UITableViewController {
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var date = NSDate()
    var descriptionText = ""
    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                self.descriptionText = location.locationDescription
                self.categoryName = location.category
                self.date = location.date
                self.coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                self.placemark = location.placemark
            }
        }
    }
    var image: UIImage? {
        didSet {
            if let image = image {
                self.imageView.image = image
                self.imageView.hidden = false
                self.imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
                self.addPhotoLabel.hidden = true
            }
        }
    }
    var observer: AnyObject!
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    @IBAction func done() {
        let hudView = HudView.hudInView(self.navigationController!.view, animated: true)
        let location: Location
        
        if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
        }
        else {
            hudView.text = "Tagged"
            location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: self.managedObjectContext) as! Location
            location.photoID = nil
        }
        
        // save the data
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        // save the image
        if let image = self.image {
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID()
            }
            
            if let data = UIImageJPEGRepresentation(image, 0.5) {
                do {
                    try data.writeToFile(location.photoPath, options: .DataWritingAtomic)
                }
                catch {
                    print("Error writing image file: \(error)")
                }
            }
        }
        
        do {
            try self.managedObjectContext.save()
        }
        catch {
            fatalCoreDataError(error)
        }
        
        // delay the closing of the view
        afterDelay(0.6) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
 
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue) {
        let controller = segue.sourceViewController as! CategoryPickerViewController
        self.categoryName = controller.selectedCategoryName
        self.categoryLabel.text = self.categoryName
    }
    
    // MARK: View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let location = self.locationToEdit {
            self.title = "Edit Location"
            if location.hasPhoto {
                if let image = location.photoImage {
                    showImage(image)
                }
            }
        }
        
        self.descriptionTextView.text = self.descriptionText
        self.categoryLabel.text = self.categoryName
        self.latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        self.longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        if let placemark = placemark {
            addressLabel.text = stringFromPlacemark(placemark)
        } else {
            addressLabel.text = "No Address Found"
        }
        self.dateLabel.text = formatDate(self.date)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LocationDetailsViewController.hideKeyboard(_:)))
        gestureRecognizer.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(gestureRecognizer)
        listenForBackgroundNotification()
    }
    
    deinit {
        print("** denit \(self) ***")
        NSNotificationCenter.defaultCenter().removeObserver(self.observer)
    }
    
    func hideKeyboard(gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.locationInView(self.tableView)
        let indexPath = self.tableView.indexPathForRowAtPoint(point)
        
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {
            return
        }
        
        self.descriptionTextView.resignFirstResponder()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategoryName = self.categoryName
        }
    }
    
    // MARK: Table Methods
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 88
        }
        else if indexPath.section == 1 {
            if self.imageView.hidden {
                return 44
            }
            else {
                return 280
            }
        }
        else if indexPath.section == 2 && indexPath.row == 2 {
            addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            addressLabel.frame.origin.y = 12
            return addressLabel.frame.size.height + 20
        }
        else {
            return 44
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        }
        else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            self.descriptionTextView.becomeFirstResponder()
        }
        else if indexPath.section == 1 && indexPath.row == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            pickPhoto()
        }
    }
    
    // MARK: Helper Methods
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var line = ""
        line.addText(placemark.subThoroughfare)
        line.addText(placemark.thoroughfare, withSeparator: " ")
        
        line.addText(placemark.locality, withSeparator: ", ")
        line.addText(placemark.administrativeArea, withSeparator: ", ")
        line.addText(placemark.postalCode, withSeparator: " ")
        line.addText(placemark.country, withSeparator: ", ")
        
        return line
    }
    
    func formatDate(date: NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
    
    func showImage(image: UIImage) {
        self.imageView.image = image
        self.imageView.hidden = false
        self.imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        self.addPhotoLabel.hidden = true
    }
    
    func listenForBackgroundNotification() {
        self.observer = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] _ in
            if let strongSelf = self {
                if strongSelf.presentedViewController != nil {
                    strongSelf.dismissViewControllerAnimated(false, completion: nil)
                }
                strongSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func pickPhoto() {
        if true || UIImagePickerController.isSourceTypeAvailable(.Camera) {
            showPhotoMenu()
        }
        else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil,preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        let takePhotoAction = UIAlertAction(title: "Take Photo",
                                            style: .Default, handler: {_ in self.takePhotoWithCamera()})
        alertController.addAction(takePhotoAction)
        let chooseFromLibraryAction = UIAlertAction(title:
            "Choose From Library", style: .Default, handler: {_ in self.choosePhotoFromLibrary()})
        alertController.addAction(chooseFromLibraryAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .Camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        self.image = info[UIImagePickerControllerEditedImage] as? UIImage
        self.tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
