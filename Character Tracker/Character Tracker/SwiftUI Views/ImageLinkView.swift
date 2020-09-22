//
//  ImageLinkView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/17/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ImageLinkView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var imageLinkController: ImageLinkController
    
    @State private var imageURL: URL? = nil
    @State private var markedForDelete = false
    
    @ObservedObject var imageLink: ImageLink
    var insertNewImage: (ImageLink) -> Void
    
    var cancelButton: some View {
        Button("Cancel") {
            self.markedForDelete = true
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    var doneButton: some View {
        Button("Done") {
            self.presentationMode.wrappedValue.dismiss()
            self.insertNewImage(self.imageLink)
        }
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Image URL", text: $imageLink.wrappedID, onCommit: {
                    guard let imageURL = URL(string: self.imageLink.wrappedID) else { return }
                    self.imageURL = imageURL
                })
            }
            
            Section(header: Text("Preview")) {
                WebImage(url: imageURL)
                    .resizable()
                    .scaledToFit()
            }
        }
        .navigationBarTitle("New Image")
        .navigationBarItems(leading: cancelButton, trailing: doneButton)
        .onDisappear {
            if self.markedForDelete {
                self.imageLinkController.delete(self.imageLink, context: self.moc)
            } else if !self.presentationMode.wrappedValue.isPresented {
                self.imageLinkController.saveOrDeleteIfInvalid(self.imageLink, context: self.moc)
            }
        }
    }
}
