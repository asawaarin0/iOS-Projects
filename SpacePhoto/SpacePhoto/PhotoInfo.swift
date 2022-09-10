//
//  PhotoInfo.swift
//  SpacePhoto
//
//  Created by Arin Asawa on 7/29/20.
//  Copyright © 2020 Arin Asawa. All rights reserved.
//

import Foundation

struct PhotoInfo:Codable{
    var title:String
    var description:String
    var url:URL
    var copyright:String?
    
    init(from decoder:Decoder) throws {
        let valueContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try valueContainer.decode(String.self, forKey: CodingKeys.title)
        self.description = try valueContainer.decode(String.self, forKey: CodingKeys.description)
        self.url = try valueContainer.decode(URL.self, forKey: CodingKeys.url)
        self.copyright = try? valueContainer.decode(String.self, forKey: CodingKeys.copyright)
    }
    
    enum CodingKeys:String,CodingKey{
        case title
        case description = "explanation"
        case url
        case copyright
    }
}
