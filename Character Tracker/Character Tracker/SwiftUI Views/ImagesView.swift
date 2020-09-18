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
    @Environment(\.managedObjectContext) var moc
    
    var imageLinkController = ImageLinkController()
    
    @State private var newImage: ImageLink?
    
    var images: [ImageLink]
    var insertNewImage: (ImageLink) -> Void
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(images, id: \.self) { image in
                    WebImage(url: URL(string: image.id ?? ""))
                        .resizable()
                        .scaledToFill()
                }
                
                Button("Add New") {
                    let newImage = ImageLink(context: self.moc)
                    self.newImage = newImage
                    self.insertNewImage(newImage)
                }
            }
        }
        .frame(height: 200)
        .sheet(item: $newImage) { imageLink in
            NavigationView {
                ImageLinkView(imageLink: imageLink)
                    .environment(\.managedObjectContext, self.moc)
                    .environmentObject(self.imageLinkController)
            }
        }
    }
}
