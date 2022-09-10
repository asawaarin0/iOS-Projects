//
//  AdviceDataModel.swift
//  Advice
//
//  Created by Arin Asawa on 3/19/21.
//

import Foundation
import Combine

struct Advice:Codable{
    var id:Int
    var text:String
    
    enum CodingKeys:String,CodingKey{
        case id = "id"
        case text = "advice"
    }
}

struct Slip:Codable{
    var advice:Advice
    static var tasks = [AnyCancellable]()
    enum CodingKeys:String,CodingKey{
        case advice = "slip"
    }
}

