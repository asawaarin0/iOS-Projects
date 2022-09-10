//
//  ViewController.swift
//  SpacePhoto
//
//  Created by Arin Asawa on 7/29/20.
//  Copyright © 2020 Arin Asawa. All rights reserved.
//

import UIKit
import AVKit

class PhotoDetailViewController: UIViewController {
    
    
    let photoInfoController = PhotoController()
    var date:String?
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var copyrightLabel: UILabel!
    var alertController:UIAlertController!
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionLabel.text = ""
        copyrightLabel.text = ""
        if let date = self.date{
            photoInfoController.query["date"] = date
        }else{
            photoInfoController.query["date"] = nil
        }
        showLoadingAnimation()
   
    }
    
    func updateUI(with photoInfo:PhotoInfo){
        let url = photoInfo.url
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, let image = UIImage(data: data){
                DispatchQueue.main.async {
                    self.imageView.image = image
                    self.navigationItem.title = photoInfo.title
                    self.descriptionLabel.text = photoInfo.description
                    if let copyright = photoInfo.copyright{
                    self.copyrightLabel.text = "Copyright \(copyright)"
                    }else{
                        self.copyrightLabel.isHidden = true
                    }
                }
            }else{
                DispatchQueue.main.async {
                    let label = UILabel()
                    label.text = "Sorry Could Not Load The Picture Of The Day!"
                    label.textColor = .black
                    label.textAlignment = .center
                    label.font = UIFont.systemFont(ofSize: 15)
                    label.frame = CGRect(x: 50, y: self.view.center.y, width: label.intrinsicContentSize.width, height: label.intrinsicContentSize.height)
                    self.view.addSubview(label)
        
                }
            }
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }.resume()
       
    }
    
    func showLoadingAnimation(){
        self.alertController = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alertController.view.addSubview(loadingIndicator)
        present(alertController, animated: true) {
            self.photoInfoController.fetchPhotoInfo { (photoInfo) in
                 guard let photoInfo = photoInfo else {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: nil)
                    }
                    return
                 }
                 self.updateUI(with: photoInfo)
             }
        }
    }
}

