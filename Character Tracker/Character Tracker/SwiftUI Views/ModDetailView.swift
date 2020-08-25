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
                SwiftUI.Section {
                    TextField("Name", text: $mod.wrappedName)
                }
                
                ModulesSection(mod: mod)
                
                SwiftUI.Section {
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
                /*
                SwiftUI.Section {
                    Button("Save") {
                        guard !self.name.isEmpty else { return }
                        
                        self.modController.update(mod: self.mod!, name: self.name, context: self.moc)
                        
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
 */
        }
        .navigationBarTitle("Mod")
        .onDisappear {
            if !self.presentationMode.wrappedValue.isPresented {
                self.modController.deleteIfEmpty(self.mod, context: self.moc)
            }
        }
    }
}

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
    var fetchRequest: FetchRequest<Module>
    
    var type: ModuleType
    
    init(mod: Mod, type: ModuleType) {
        self.type = type
        self.fetchRequest = FetchRequest(entity: Module.entity(), sortDescriptors: [], predicate: NSPredicate(format: "mod = %@ AND type = %@", mod, type))
    }
    
    var body: some View {
        SwiftUI.Section(header: Text(type.typeName)) {
            ForEach (fetchRequest.wrappedValue, id: \.self) { module in
                Text(module.name ?? "Unknown module")
            }
        }
    }
}
/*
struct ModDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ModDetailView()
    }
}
*/
