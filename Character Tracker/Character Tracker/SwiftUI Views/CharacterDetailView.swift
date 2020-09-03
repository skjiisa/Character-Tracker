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
    @State private var showingRaces = false
    
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
                
                if editMode {
                    NavigationLink(character.race?.name ?? "Select Race", destination: RacesView(game: character.game) { race in
                        self.showingRaces = false
                        self.character.race = race
                    }, isActive: $showingRaces)
                } else {
                    Text(character.race?.name ?? "Select Race")
                }
            }
        }
        .navigationBarTitle(character.name ?? "New Character")
        .navigationBarItems(trailing: editButton)
    }
}
