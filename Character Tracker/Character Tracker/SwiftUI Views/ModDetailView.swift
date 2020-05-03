//
//  ModDetailView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ModDetailView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var modController: ModController
    
    @State private var name = ""
    
    var mod: Mod?

    init(mod: Mod? = nil) {
        self.mod = mod
        _name = .init(initialValue: self.mod?.name ?? "")
    }
    
    var body: some View {
        Form {
            SwiftUI.Section {
                TextField("Name", text: $name)
            }
            
            SwiftUI.Section {
                Button("Save") {
                    guard !self.name.isEmpty else { return }
                    self.modController.create(mod: self.name, context: self.moc)
                    
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationBarTitle(mod?.name ?? "New Mod")
    }
}

struct ModDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ModDetailView()
    }
}
