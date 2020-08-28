//
//  ModDetailView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ModDetailView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var ingredientsFetchRequest: FetchRequest<Ingredient>
    var ingredients: FetchedResults<Ingredient> {
        ingredientsFetchRequest.wrappedValue
    }
    
    @EnvironmentObject var modController: ModController
    
    @ObservedObject var mod: Mod
    @State private var showingNewModule = false
    @State private var showingNewIngredient = false
    
    init(mod: Mod) {
        self.mod = mod
        
        // The mod's ingredients property will give an optional, unordered
        // NSSet which will be harder to deal with declaratively than a
        // fetch request with a sort descriptor.
        self.ingredientsFetchRequest = FetchRequest(entity: Ingredient.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: NSPredicate(format: "mod = %@", mod))
    }
    
    var body: some View {
        Form {
            
            // Images
            
            if mod.images?.count ?? 0 > 0 {
                Section {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(mod.images!.array as! [ImageLink], id: \.self) { image in
                                WebImage(url: URL(string: image.id ?? ""))
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                    }
                    .frame(height: 200)
                }
            }
            
            // Name
            
            Section {
                TextField("Name", text: $mod.wrappedName)
            }
            
            // Modules
            
            ModulesSection(mod: mod)
            
            Section {
                NavigationLink("Add module", destination: ModulesView() { module in
                    // If this showingNewModule isn't here, trying to add a module
                    // to the mod will cause a new copy of ModulesView to get pushed
                    // on top of the old one before popping back to this view.
                    // Popping it first by setting showingNewModule to false fixes that.
                    self.showingNewModule = false
                    self.modController.add(module, to: self.mod, context: self.moc)
                }, isActive: $showingNewModule)
            }
            
            // Ingredients
            
            if ingredients.count > 0 {
                Section(header: Text("Ingredients")) {
                    ForEach(ingredients, id: \.self) { ingredient in
                        Text(ingredient.name ?? "Unknown ingredient")
                    }
                    .onDelete { indexSet in
                        guard let index = indexSet.first else { return }
                        let ingredient = self.ingredients[index]
                        self.modController.remove(ingredient, from: self.mod, context: self.moc)
                    }
                }
            }
            
            Section() {
                NavigationLink("Add ingredient", destination: IngredientsView() { ingredient in
                    self.showingNewIngredient = false
                    self.modController.add(ingredient, to: self.mod, context: self.moc)
                }, isActive: $showingNewIngredient)
            }
        }
        .navigationBarTitle(mod.name ?? "Mod")
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
    var modules: FetchedResults<Module> {
        fetchRequest.wrappedValue
    }
    
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
            if modules.count > 0 {
                Section(header: Text(type.typeName)) {
                    ForEach (modules, id: \.self) { module in
                        Text(module.name ?? "Unknown module")
                    }
                    .onDelete { indexSet in
                        guard let index = indexSet.first else { return }
                        let module = self.modules[index]
                        self.modController.remove(module, from: self.mod, context: self.moc)
                    }
                }
            }
        }
    }
}
