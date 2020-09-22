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
    
    var gamesFetchRequest: FetchRequest<Game>
    var games: FetchedResults<Game> {
        gamesFetchRequest.wrappedValue
    }
    
    @EnvironmentObject var modController: ModController
    @ObservedObject var gameController = GameController()
    
    @ObservedObject var mod: Mod
    
    @State private var showingNewModule = false
    @State private var showingNewIngredient = false
    @State private var editMode = false
    @State private var selectedIngredient: Ingredient?
    @State private var showingExport = false
    @State private var qrCode: CGImage? = nil
    @State private var exportJSON: String? = nil
    @State private var exportFile: URL? = nil
    @State private var showingShareSheet = false
    
    init(mod: Mod) {
        self.mod = mod
        
        // The mod's ingredients property will give an optional, unordered
        // NSSet which will be harder to deal with declaratively than a
        // fetch request with a sort descriptor.
        self.ingredientsFetchRequest = FetchRequest(entity: Ingredient.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: NSPredicate(format: "%@ in mods", mod))
        
        self.gamesFetchRequest = FetchRequest(entity: Game.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: NSPredicate(format: "ANY mods == %@", mod))
    }
    
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
            
            // Images
            
            Section {
                ImagesView(images: mod.images!.array as! [ImageLink]) { imageLink in
                    self.mod.mutableOrderedSetValue(forKey: "images").add(imageLink)
                }
            }
            
            // Name
            
            if editMode {
                Section {
                    TextField("Name", text: $mod.wrappedName)
                }
            }
            
            // Modules
            
            ModulesSection(mod: mod, deleteDisabled: !editMode)
            
            if editMode {
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
            }
            
            //MARK: Ingredients
            
            if ingredients.count > 0 {
                Section(header: Text("Ingredients")) {
                    ForEach(ingredients, id: \.self) { ingredient in
                        Button(ingredient.name ?? "Unknown ingredient") {
                            self.selectedIngredient = ingredient
                        }
                        .foregroundColor(.primary)
                    }
                    .onDelete { indexSet in
                        guard let index = indexSet.first else { return }
                        let ingredient = self.ingredients[index]
                        self.modController.remove(ingredient, from: self.mod, context: self.moc)
                    }
                    .deleteDisabled(!editMode)
                }
            }
            
            if editMode {
                Section {
                    NavigationLink("Add ingredient", destination: IngredientsView() { ingredient in
                        self.showingNewIngredient = false
                        self.modController.add(ingredient, to: self.mod, context: self.moc)
                    }, isActive: $showingNewIngredient)
                }
            }
            
            //MARK: Games
            
            Section(header: Text("Games")) {
                ForEach(games) { game in
                    Text(game.name ?? "Unknown game")
                }
            }
            
            if editMode {
                Section {
                    NavigationLink("Select games", destination:
                        GamesView(mod: mod, gameController: gameController)
                    )
                        
                }
            }
            
            //MARK: Export
            
            if !editMode {
                Section {
                    Button(action: {
                        self.showingExport = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Export")
                            Spacer()
                        }
                    }
                    .sheet(isPresented: $showingShareSheet, onDismiss: {
                        if self.exportFile != nil {
                            PortController.shared.clearFilesFromTempDirectory()
                        }
                        self.exportJSON = nil
                        self.exportFile = nil
                    }) {
                        if self.exportJSON != nil {
                            ShareSheet(activityItems: [self.exportJSON!])
                        } else if self.exportFile != nil {
                            ShareSheet(activityItems: [self.exportFile!])
                        }
                    }
                }
            }
        }
        .navigationBarTitle(mod.name ?? "Mod")
        .navigationBarItems(trailing: editButton)
        .onDisappear {
            if !self.presentationMode.wrappedValue.isPresented {
                self.modController.saveOrDeleteIfEmpty(self.mod, context: self.moc)
            }
        }
        .alert(item: $selectedIngredient) { ingredient in
            Alert(title: Text(ingredient.name ?? "Unknown ingredient"), message: Text("Plugin and FormID:\n\(ingredient.id ?? "")"))
        }
        .actionSheet(isPresented: $showingExport) {
            ActionSheet(title: Text("Export \(self.mod.name ?? "mod")"), message: nil, buttons: [
                .default(Text("QR Code")) {
                    self.qrCode = PortController.shared.exportToQRCode(for: self.mod)
                },
                .default(Text("JSON Text")) {
                    guard let json = PortController.shared.exportJSONText(for: self.mod) else { return }
                    self.exportJSON = json
                    self.showingShareSheet = true
                },
                .default(Text("JSON File")) {
                    guard let file = PortController.shared.saveTempJSON(for: self.mod) else { return }
                    self.exportFile = file
                    self.showingShareSheet = true
                },
                .cancel()
            ])
        }
        .sheet(item: self.$qrCode) { qrCode in
            NavigationView {
                QRCodeView(name: self.mod.name, qrCode: qrCode)
            }
        }
    }
}

//MARK: Modules

struct ModulesSection: View {
    @FetchRequest(entity: ModuleType.entity(), sortDescriptors: []) var types: FetchedResults<ModuleType>
    
    var mod: Mod
    var deleteDisabled: Bool
    
    var body: some View {
        ForEach(types, id: \.self) { type in
            ModuleTypeSection(mod: self.mod, type: type, deleteDisabled: self.deleteDisabled)
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
    @EnvironmentObject var gameReference: GameReference
    
    @State private var showingModule: Module?
    
    var mod: Mod
    var type: ModuleType
    var deleteDisabled: Bool
    
    init(mod: Mod, type: ModuleType, deleteDisabled: Bool) {
        self.mod = mod
        self.type = type
        self.deleteDisabled = deleteDisabled
        self.fetchRequest = FetchRequest(entity: Module.entity(), sortDescriptors: [], predicate: NSPredicate(format: "mod = %@ AND type = %@", mod, type))
    }
    
    var body: some View {
        // I honestly don't really like this solution using Group
        // since it adds so many layers, but we can't have the if
        // statement top-level or do the check in the parent view
        // with how things are set up right now.
        Group {
            if modules.count > 0 {
                Section(header: Text(type.typeName.pluralize())) {
                    ForEach (modules, id: \.self) { module in
                        // I would have preferred to have navigation links here,
                        // but since ModuleDetailView is currently just a container
                        // for a UITableView, the navigation bar gets all messed up
                        // when you try navigating to it from SwiftUI.
                        Button(module.name ?? "Unknown module") {
                            self.showingModule = module
                        }
                        .foregroundColor(.primary)
                    }
                    .onDelete { indexSet in
                        guard let index = indexSet.first else { return }
                        let module = self.modules[index]
                        self.modController.remove(module, from: self.mod, context: self.moc)
                    }
                    .deleteDisabled(deleteDisabled)
                }
            }
        }
        .sheet(item: $showingModule) { module in
            ModuleDetailView(module: module)
                .environmentObject(self.gameReference)
        }
    }
}
