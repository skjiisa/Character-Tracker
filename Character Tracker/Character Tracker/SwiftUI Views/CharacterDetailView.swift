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
                            CharacterModuleSection(section.section as! ModuleType, character: self.character)
                        } else if section.section is AttributeTypeSection {
                            CharacterAttributeSection(section.section as! AttributeTypeSection, character: self.character)
                        }
                    }
                }
            }
        }
        .navigationBarTitle(character.name ?? "New Character")
        .navigationBarItems(trailing: editButton)
    }
}

struct CharacterModuleSection: View {
    var fetchRequest: FetchRequest<CharacterModule>
    var characterModules: FetchedResults<CharacterModule> {
        fetchRequest.wrappedValue
    }
    
    @EnvironmentObject var gameReference: GameReference
    
    @State private var showingModule: CharacterModule?
    
    var type: ModuleType
    var character: Character
    
    init(_ type: ModuleType, character: Character) {
        self.type = type
        self.character = character
        
        let predicate = NSPredicate(format: "character == %@ AND module.type == %@", character, type)
        self.fetchRequest = FetchRequest(entity: CharacterModule.entity(),
                                         sortDescriptors: [
                                            NSSortDescriptor(key: "module.level", ascending: true),
                                            NSSortDescriptor(key: "module.name", ascending: true)],
                                         predicate: predicate)
    }
    
    var body: some View {
        ForEach(characterModules, id: \.self) { characterModule in
            Button(action: {
                self.showingModule = characterModule
            }) {
                HStack {
                    Text(characterModule.module?.name ?? "Unknown \(self.type.typeName)")
                    Spacer()
                    if characterModule.module?.level ?? 0 > 0 {
                        Text("Level \(characterModule.module?.level ?? 0)")
                    }
                    if characterModule.completed {
                        Image(systemName: "checkmark")
                            .font(Font.body.bold())
                            .foregroundColor(.green)
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .sheet(item: $showingModule) { characterModule in
            ModuleDetailView(characterModule: characterModule)
                .environmentObject(self.gameReference)
        }
    }
}

struct CharacterAttributeSection: View {
    var fetchRequest: FetchRequest<CharacterAttribute>
    var characterAttributes: FetchedResults<CharacterAttribute> {
        fetchRequest.wrappedValue
    }
    
    var type: AttributeTypeSection
    
    init(_ type: AttributeTypeSection, character: Character) {
        self.type = type
        
        let predicate = NSPredicate(format: "character == %@ AND attribute.type == %@ AND priority == %d", character, type.type!, type.minPriority)
        self.fetchRequest = FetchRequest(entity: CharacterAttribute.entity(),
                                         sortDescriptors: [],
                                         predicate: predicate)
    }
    
    var body: some View {
        ForEach(characterAttributes, id: \.self) { characterAttribute in
            Text(characterAttribute.attribute?.name ?? "Unknown \(self.type.typeName)")
        }
    }
}
