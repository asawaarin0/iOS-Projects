//
//  PhotoDatePickerViewController.swift
//  SpacePhoto
//
//  Created by Arin Asawa on 8/2/20.
//  Copyright © 2020 Arin Asawa. All rights reserved.
//

import UIKit

class PhotoDatePickerViewController: UIViewController {

    @IBOutlet var photoDatePicker: UIDatePicker!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.photoDatePicker.date = Date()
        self.photoDatePicker.maximumDate = Date()
        self.navigationController?.navigationBar.isHidden = true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! PhotoDetailViewController
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        destination.date = formatter.string(from: photoDatePicker.date)
        self.navigationController?.navigationBar.isHidden = false
    }

    

}
