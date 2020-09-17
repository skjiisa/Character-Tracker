//
//  ImagesView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/16/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ImagesView: View {
    var images: [ImageLink]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(images, id: \.self) { image in
                    WebImage(url: URL(string: image.id ?? ""))
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .frame(height: 200)
    }
}
