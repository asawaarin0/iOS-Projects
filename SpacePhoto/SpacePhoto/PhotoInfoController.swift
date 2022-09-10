//
//  PhotoInfoController.swift
//  SpacePhoto
//
//  Created by Arin Asawa on 7/29/20.
//  Copyright © 2020 Arin Asawa. All rights reserved.
//

import Foundation



class PhotoController{
    var query:[String:String]=[
          "api_key":"MLjkhVTL3mcSP4gQddaDa2JRq8o5dR6CSztaiD00",
          "date":"2010-07-28"
      ]

func fetchPhotoInfo(completion: @escaping (PhotoInfo?)->Void){
    let baseURL = URL(string: "https://api.nasa.gov/planetary/apod")!
    let url = baseURL.withQueries(query)!
    var pictureInfo:PhotoInfo?
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
       let jsonDecoder = JSONDecoder()
        if let data = data, let photoInfo = try? jsonDecoder.decode(PhotoInfo.self, from: data){
            completion(photoInfo)
        }else{
            print("either no data was returned or data was not properly decoded")
            completion(nil)
        }
    }
    task.resume()
    
}


}
