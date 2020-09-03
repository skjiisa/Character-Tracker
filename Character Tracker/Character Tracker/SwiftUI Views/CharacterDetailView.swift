//
//  CharacterDetailView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/2/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct CharacterDetailView: View {
    
    @ObservedObject var character: Character
    
    @State private var editMode = false
    
    var editButton: some View {
        Button(action: {
            self.editMode.toggle()
        }) {
            if editMode {
                Text("Done")
            } else {
                Text("Edit")
            }
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("CHARACTER")) {
                HStack {
                    TextField("Name", text: $character.wrappedName)
                        .disabled(!editMode)
                    Picker("Gender", selection: $character.female) {
                        Text("Male").tag(false)
                        Text("Female").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!editMode)
                }
            }
        }
        .navigationBarTitle(character.name ?? "New Character")
        .navigationBarItems(trailing: editButton)
    }
}
