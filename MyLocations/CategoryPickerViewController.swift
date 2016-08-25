//
//  CategoryPickerViewController.swift
//  MyLocations
//
//  Created by Aseem Kohli on 8/8/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
    var selectedCategoryName = ""
    
    let categories = [ "No Category", "Apple Store", "Bar", "Bookstore", "Club",
                       "Grocery Store", "Historic Building", "House",
                       "Icecream Vendor", "Landmark",
                       "Park"]
    
    var selectedIndexPath = NSIndexPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<self.categories.count {
            if categories[i] == self.selectedCategoryName {
                self.selectedIndexPath = NSIndexPath(forRow: i, inSection: 0)
                break
            }
        }
        
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        tableView.indicatorStyle = .White
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickedCategory" {
            let cell = sender as! UITableViewCell
            if let indexPath = self.tableView.indexPathForCell(cell) {
                self.selectedCategoryName = self.categories[indexPath.row]
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("CategoryCell", forIndexPath: indexPath)
        let categoryName = categories[indexPath.row]
        cell.textLabel!.text = categoryName
        if categoryName == self.selectedCategoryName {
            cell.accessoryType = .Checkmark
        }
        else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.blackColor()
        if let textLabel = cell.textLabel {
            textLabel.textColor = UIColor.whiteColor()
            textLabel.highlightedTextColor = textLabel.textColor
        }
        let selectionView = UIView(frame: CGRect.zero)
        selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        cell.selectedBackgroundView = selectionView
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row != self.selectedIndexPath.row {
            if let newCell = tableView.cellForRowAtIndexPath(indexPath) {
                newCell.accessoryType = .Checkmark
            }
            
            if let oldCell = tableView.cellForRowAtIndexPath(self.selectedIndexPath) {
                oldCell.accessoryType = .None
            }
            
            self.selectedIndexPath = indexPath
        }
    }
}
