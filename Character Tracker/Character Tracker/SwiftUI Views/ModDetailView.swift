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
    
    @ObservedObject var mod: Mod
    @State private var showingNewModule = false
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $mod.wrappedName)
            }
            
            ModulesSection(mod: mod)
            
            Section {
                NavigationLink(destination: ModulesView() { module in
                    // If this showingNewModule isn't here, trying to add a module
                    // to the mod will cause a new copy of ModulesView to get pushed
                    // on top of the old one before popping back to this view.
                    // Popping it first by setting showingNewModule to false fixes that.
                    self.showingNewModule = false
                    self.modController.add(module, to: self.mod, context: self.moc)
                }, isActive: $showingNewModule) {
                    Text("Add module")
                }
            }
        }
        .navigationBarTitle("Mod")
        .onDisappear {
            if !self.presentationMode.wrappedValue.isPresented {
                self.modController.saveOrDeleteIfEmpty(self.mod, context: self.moc)
            }
        }
    }
}

//MARK: Modules

struct ModulesSection: View {
    @FetchRequest(entity: ModuleType.entity(), sortDescriptors: []) var types: FetchedResults<ModuleType>
    
    var mod: Mod
    
    var body: some View {
        ForEach(types, id: \.self) { type in
            ModuleTypeSection(mod: self.mod, type: type)
        }
    }
}

struct ModuleTypeSection: View {
    @Environment(\.managedObjectContext) var moc
    
    var fetchRequest: FetchRequest<Module>
    
    @EnvironmentObject var modController: ModController
    
    var mod: Mod
    var type: ModuleType
    
    init(mod: Mod, type: ModuleType) {
        self.mod = mod
        self.type = type
        self.fetchRequest = FetchRequest(entity: Module.entity(), sortDescriptors: [], predicate: NSPredicate(format: "mod = %@ AND type = %@", mod, type))
    }
    
    var body: some View {
        // I honestly don't really like this solution using Group
        // since it adds so many layers, but we can't have the if
        // statement top-level or do the check in the parent view
        // with how things are set up right now.
        Group {
            if fetchRequest.wrappedValue.count > 0 {
                Section(header: Text(type.typeName)) {
                    ForEach (fetchRequest.wrappedValue, id: \.self) { module in
                        Text(module.name ?? "Unknown module")
                    }
                    .onDelete { indexSet in
                        guard let index = indexSet.first else { return }
                        let module = self.fetchRequest.wrappedValue[index]
                        self.modController.remove(module, from: self.mod, context: self.moc)
                    }
                }
            }
        }
    }
}
