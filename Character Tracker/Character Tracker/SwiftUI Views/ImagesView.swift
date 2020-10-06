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
    var parent: OrderedImages?
    var imageRemoved: (Int?) -> Void = { _ in }
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
                
                Button("Add Image") {
                    let newImage = ImageLink(context: self.moc)
                    self.newImage = newImage
                }
                .padding()
            }
        }
        .frame(height: images.count == 0 ? 20 : 200)
        .sheet(item: $newImage) { imageLink in
            NavigationView {
                ImageLinkView(imageLink: imageLink, insertNewImage: self.insertNewImage)
                    .environment(\.managedObjectContext, self.moc)
                    .environmentObject(self.imageLinkController)
            }
        }
        .alert(item: $deleteImage) { imageLink in
            Alert(title: Text("Delete this image?"), message: nil, primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete"), action: {
                let index = self.images.firstIndex(of: imageLink)
                self.imageLinkController.remove(imageLink, from: parent, context: moc)
                self.imageRemoved(index)
            }))
        }
    }
}
