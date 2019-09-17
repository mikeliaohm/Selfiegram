//
//  SettingsTableViewController.swift
//  Selfiegram
//
//  Created by Mike Liao on 2019/9/17.
//  Copyright © 2019 Mike Liao. All rights reserved.
//

import UIKit
import UserNotifications

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var reminderSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        locationSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
    }

    // MARK: - Table view data source

    @IBAction func locationSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(locationSwitch.isOn, forKey: SettingsKey.saveLocation.rawValue)
    }
    
    @IBAction func reminderSwitchToggled(_ sender: UISwitch) {
    }
    //    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }


}

enum SettingsKey: String {
    case saveLocation
}
