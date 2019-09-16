//
//  DetailViewController.swift
//  Selfiegram
//
//  Created by Mike Liao on 2019/9/5.
//  Copyright © 2019 Mike Liao. All rights reserved.
//

import UIKit
import MapKit

class SelfieDetailViewController: UIViewController {

    @IBOutlet weak var selfieNameField: UITextField!
    @IBOutlet weak var dateCreatedLabel: UILabel!
    @IBOutlet weak var selfieImageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    let dateFormatter = { () -> DateFormatter in
        let d = DateFormatter()
        d.dateStyle = .short
        d.timeStyle = .short
        return d
    }()
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.selfieNameField.resignFirstResponder()
        
        guard let selfie = selfie else {
            return
        }
        
        guard let text = selfieNameField?.text else {
            return
        }
        
        selfie.title = text
        
        try? SelfieStore.shared.save(selfie: selfie)
    }
    
    func configureView() {
        
        guard let selfie = selfie else {
            return
        }
        
        guard let selfieNameField = selfieNameField,
              let selfieImageView = selfieImageView,
              let dateCreatedLabel = dateCreatedLabel
        else {
            return
        }
        
        selfieNameField.text = selfie.title
        dateCreatedLabel.text = dateFormatter.string(from: selfie.created)
        selfieImageView.image = selfie.image
        
        if let position = selfie.position {
            self.mapView.setCenter(position.location.coordinate, animated: false)
            mapView.isHidden = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }

    var selfie: Selfie? {
        didSet {
            // Update the view.
            configureView()
        }
    }


}

