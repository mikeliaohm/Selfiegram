//
//  MasterViewController.swift
//  Selfiegram
//
//  Created by Mike Liao on 2019/9/5.
//  Copyright © 2019 Mike Liao. All rights reserved.
//

import UIKit
import CoreLocation

class SelfieListViewController: UITableViewController {

    let timeIntervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .spellOut
        formatter.maximumUnitCount = 1
        return formatter
    }()
    
    var detailViewController: SelfieDetailViewController? = nil
    var lastLocation: CLLocation?
    let locationManager = CLLocationManager()
    
    var selfies : [Selfie] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            selfies = try SelfieStore.shared.listSelfies()
                .sorted(by: { $0.created > $1.created })
        } catch let error {
            showError(message: "Failed to load selfies: \(error.localizedDescription)")
        }
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? SelfieDetailViewController
        }
        
        let addSelfieButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewSelfie))
        
        navigationItem.rightBarButtonItem = addSelfieButton
        self.locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selfies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let selfie = selfies[indexPath.row]
        cell.textLabel?.text = selfie.title
        
        if let interval = timeIntervalFormatter.string(from: selfie.created, to: Date()) {
            cell.detailTextLabel?.text = "\(interval) ago"
        } else {
            cell.detailTextLabel?.text = nil
        }
        
        cell.imageView?.image = selfie.image
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let selfieToRemove = selfies[indexPath.row]
            
            do {
                try SelfieStore.shared.delete(selfie: selfieToRemove)
                
                selfies.remove(at: indexPath.row)
                
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                let title = selfieToRemove.title
                showError(message: "Failed to delete \(title).")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            
            if let indexPath = tableView.indexPathForSelectedRow {
                let selfie = selfies[indexPath.row]
                if let controller = (
                    segue.destination as? UINavigationController)?
                    .topViewController as? SelfieDetailViewController {
                    controller.selfie = selfie
                    controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                    controller.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }
    
    @objc func createNewSelfie() {
        let shouldGetLocation = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        
        if shouldGetLocation {
            switch CLLocationManager.authorizationStatus() {
            case .denied, .restricted:
                return
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            default:
                break
            }
            
            locationManager.requestLocation()
        }
        
        
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            
            if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = .front
            } else {
                imagePicker.sourceType = .photoLibrary
            }
            
        }
        imagePicker.delegate = self
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension SelfieListViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            let message = "Couldn't get a picture from the image picker!"
            showError(message: message)
            return
        }
        
        self.newSelfieTaken(image: image)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func newSelfieTaken(image: UIImage) {
        let newSelfie = Selfie(title: "New Selfie")
        
        newSelfie.image = image
        
        if let location = self.lastLocation {
            newSelfie.position = Selfie.Coordinate(location: location)
        }
        
        do {
            try SelfieStore.shared.save(selfie: newSelfie)
        } catch let error {
            showError(message: "Can't save photo: \(error)")
            return
        }
        
        selfies.insert(newSelfie, at: 0)
        
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
}


extension SelfieListViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showError(message: error.localizedDescription)
    }
}
