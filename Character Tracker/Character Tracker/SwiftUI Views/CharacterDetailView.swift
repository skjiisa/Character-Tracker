//
//  CharacterDetailView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/2/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct CharacterDetailView: View {
    @ObservedObject var sectionController = AttributeTypeSectionController()
    
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
            
            ForEach(sectionController.tempSections(for: character), id: \.self) { section in
                Section(header:
                    Button(action: {
                        self.sectionController.toggleSection(section, for: self.character)
                    }, label: {
                        Text((section.collapsed ? "▶︎" : "▼") + "\t" + section.name.uppercased())
                        // Spacer fills the width, allowing the empty space after to be tapped too.
                        Spacer()
                    })
                    .foregroundColor(.secondary)
                ) {
                    if !section.collapsed {
                        if section.section is ModuleType {
                            ModuleSection(section.section as! ModuleType, character: self.character)
                        }
                    }
                }
            }
        }
        .navigationBarTitle(character.name ?? "New Character")
        .navigationBarItems(trailing: editButton)
    }
}

struct ModuleSection: View {
    var fetchRequest: FetchRequest<Module>
    var modules: FetchedResults<Module> {
        fetchRequest.wrappedValue
    }
    
    @EnvironmentObject var gameReference: GameReference
    
    @State private var showingModule: Module?
    
    var type: ModuleType
    
    init(_ type: ModuleType, character: Character) {
        self.type = type
        
        let predicate = NSPredicate(format: "type == %@ AND SUBQUERY(characters, $characterModule, $characterModule.module == self AND $characterModule.character = %@).@count > 0", type, character)
        self.fetchRequest = FetchRequest(entity: Module.entity(),
                                         sortDescriptors: [
                                            NSSortDescriptor(key: "level", ascending: true),
                                            NSSortDescriptor(key: "name", ascending: true)],
                                         predicate: predicate)
    }
    
    var body: some View {
        ForEach(modules, id: \.self) { module in
            Button(action: {
                self.showingModule = module
            }) {
                HStack {
                    Text(module.name ?? "Unknown \(self.type.typeName)")
                    Spacer()
                    Text("Level \(module.level)")
                }
                .foregroundColor(.primary)
            }
        }
        .sheet(item: $showingModule) { module in
            ModuleDetailView(module: module)
                .environmentObject(self.gameReference)
        }
    }
}
