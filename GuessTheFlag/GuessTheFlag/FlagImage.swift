//
//  FlagImage.swift
//  GuessTheFlag
//
//  Created by Arin Asawa on 9/1/20.
//  Copyright © 2020 Arin Asawa. All rights reserved.
//

import SwiftUI

struct FlagImage: View {
    var uiImage:UIImage
    var body: some View {
        ZStack{
                Image(uiImage: uiImage)
                 .renderingMode(.original)
                 .clipShape(Capsule())
                 .overlay(Capsule().stroke(Color.black,lineWidth: 1))
                 .shadow(color: Color.black, radius: 2)
           
    }
    }
    
}


