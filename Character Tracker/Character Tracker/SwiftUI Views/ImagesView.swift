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
    @State private var deleteImage: ImageLink?
    
    var images: [ImageLink]
    var insertNewImage: (ImageLink) -> Void
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(images, id: \.self) { image in
                    WebImage(url: URL(string: image.id ?? ""))
                        .resizable()
                        .scaledToFill()
                        .onTapGesture {
                            self.deleteImage = image
                    }
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
        .alert(item: $deleteImage) { imageLink in
            Alert(title: Text("Delete this image?"), message: nil, primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete"), action: {
                self.imageLinkController.delete(imageLink, context: self.moc)
            }))
        }
    }
}
