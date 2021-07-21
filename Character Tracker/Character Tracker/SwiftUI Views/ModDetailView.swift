//
//  ModDetailView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ActionOver

struct ModDetailView: View {
    
    //MARK: Properties
    
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
    @EnvironmentObject var gameReference: GameReference
    @ObservedObject var gameController = GameController()
    
    @ObservedObject var mod: Mod
    
    @State private var showingNewModule = false
    @State private var showingNewIngredient = false
    @State private var editMode: Bool
    @State private var selectedIngredient: Ingredient?
    @State private var showingExport = false
    @State private var qrCodeBuffer: CGImage? = nil
    @State private var qrCode: CGImage? = nil
    @State private var exportJSON: String? = nil
    @State private var exportFile: URL? = nil
    @State private var showingShareSheet = false
    
    init(mod: Mod, editMode: Bool = false) {
        self.mod = mod
        
        // The mod's ingredients property will give an optional, unordered
        // NSSet which will be harder to deal with declaratively than a
        // fetch request with a sort descriptor.
        self.ingredientsFetchRequest = FetchRequest(entity: Ingredient.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: NSPredicate(format: "%@ in mods", mod))
        
        self.gamesFetchRequest = FetchRequest(entity: Game.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: NSPredicate(format: "ANY mods == %@", mod))
        
        _editMode = .init(initialValue: editMode)
    }
    
    var exportButtons: [ActionOverButton] {
        var actions: [ActionOverButton] = [
            ActionOverButton(title: "JSON Text", type: .normal) {
                guard let json = PortController.shared.exportJSONText(for: self.mod) else { return }
                self.exportJSON = json
                self.showingShareSheet = true
            },
            ActionOverButton(title: "JSON File", type: .normal) {
                guard let file = PortController.shared.saveTempJSON(for: self.mod) else { return }
                self.exportFile = file
                self.showingShareSheet = true
            },
            ActionOverButton(title: nil, type: .cancel, action: nil)
        ]
        
        if qrCodeBuffer != nil {
            actions.insert(
                ActionOverButton(title: "QR Code", type: .normal) {
                    qrCode = qrCodeBuffer
                }, at: 0)
        }
        
        return actions
    }
    
    //MARK: Views
    
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
    
    //MARK: Body
    
    var body: some View {
        Form {
            
            // Images
            
            Section {
                ImagesView(images: mod.images!.array as! [ImageLink], parent: mod) { imageLink in
                    self.mod.mutableOrderedSetValue(forKey: "images").add(imageLink)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
                    }.environment(\.managedObjectContext, moc),
                    isActive: $showingNewModule)
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
                        let ingredientsToRemove = indexSet.map { ingredients[$0] }
                        DispatchQueue.main.async {
                            modController.remove(ingredientsToRemove, from: mod, context: moc)
                        }
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
                        self.qrCodeBuffer = PortController.shared.exportToQRCode(for: self.mod)
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
                    // I wish I could just use the ActionSheet here that was in
                    // earlier builds, but the popover location is busted on iPad.
                    // I'm pretty sure it's just a SwiftUI bug.
                    .actionOver(presented: $showingExport,
                                title: "Export \(self.mod.name ?? "mod")",
                                message: qrCodeBuffer == nil ? "Mod too large to generate QR code." : nil,
                                buttons: exportButtons,
                                ipadAndMacConfiguration: IpadAndMacConfiguration(anchor: nil, arrowEdge: nil),
                                normalButtonColor: UIColor.systemBlue)
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
        .sheet(item: self.$qrCode) { qrCode in
            NavigationView {
                QRCodeView(name: self.mod.name, qrCode: qrCode)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

//MARK: Modules

struct ModulesSection: View {
    @FetchRequest(entity: ModuleType.entity(), sortDescriptors: []) var types: FetchedResults<ModuleType>
    
    var mod: Mod
    var deleteDisabled: Bool
    
    var body: some View {
        ForEach(types) { type in
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
                    ForEach (modules) { module in
                        // I would have preferred to have navigation links here,
                        // but since ModuleDetailView is currently just a container
                        // for a UITableView, the navigation bar gets all messed up
                        // when you try navigating to it from SwiftUI.
                        Button(module.name ?? "Unknown module") {
                            self.showingModule = module
                        }
                        .foregroundColor(.primary)
                        .sheet(item: $showingModule) { module in
                            ModuleDetailView(module: module)
                                .environmentObject(gameReference)
                                .environment(\.managedObjectContext, moc)
                        }
                    }
                    .onDelete { indexSet in
                        let modulesToRemove = indexSet.map { modules[$0] }
                        DispatchQueue.main.async {
                            modController.remove(modulesToRemove, from: mod, context: moc)
                        }
                    }
                    .deleteDisabled(deleteDisabled)
                }
            }
        }
    }
}
