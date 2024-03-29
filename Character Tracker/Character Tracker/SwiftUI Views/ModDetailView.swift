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
import Introspect
import AlertToast

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
    @StateObject private var gameController = GameController()
    @StateObject private var linkController = LinkController()
    
    @ObservedObject var mod: Mod
    
    @State private var showingNewModule = false
    @State private var showingNewIngredient = false
    @State private var editMode: Bool
    @State private var selectedIngredient: Ingredient?
    @State private var showingExport = false
    @State private var qrCodes: QRCodes? = nil
    @State private var exportJSON: String? = nil
    @State private var exportFile: URL? = nil
    @State private var showingShareSheet = false
    @State private var showingLoading = false
    @State private var vc: UIViewController?
    
    init(mod: Mod, editMode: Bool = false) {
        self.mod = mod
        
        // The mod's ingredients property will give an optional, unordered
        // NSSet which will be harder to deal with declaratively than a
        // fetch request with a sort descriptor.
        self.ingredientsFetchRequest = FetchRequest(entity: Ingredient.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: NSPredicate(format: "%@ in mods", mod))
        
        self.gamesFetchRequest = FetchRequest(entity: Game.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: NSPredicate(format: "ANY mods == %@", mod))
        
        _editMode = .init(initialValue: editMode)
    }
    
    var exportButtons: [ActionOverButton] {[
        ActionOverButton(title: "QR Codes", type: .normal) {
            // Generating the QR codes can take a long time.
            showingLoading = true
            DispatchQueue.global(qos: .userInitiated).async {
                let codes = PortController.shared.exportToQRCodes(for: mod)
                DispatchQueue.main.async {
                    // The QRCodes initializer will fail if the the array is empty,
                    // but nil-coalescing here is easier than unmrapping codes.
                    qrCodes = QRCodes(codes ?? [])
                    showingLoading = false
                }
            }
        },
        ActionOverButton(title: "JSON Text", type: .normal) {
            guard let json = PortController.shared.exportJSONText(for: mod) else { return }
            exportJSON = json
            showingShareSheet = true
        },
        ActionOverButton(title: "JSON File", type: .normal) {
            guard let file = PortController.shared.saveTempJSON(for: mod) else { return }
            exportFile = file
            showingShareSheet = true
        },
        ActionOverButton(title: nil, type: .cancel, action: nil)
    ]}
    
    //MARK: Views
    
    var editButton: some View {
        Button(editMode ? "Done" : "Edit") {
            withAnimation {
                editMode.toggle()
            }
        }
    }
    
    //MARK: Body
    
    var body: some View {
        Form {
            
            // Images
            
            Section {
                ImagesView(images: mod.images?.array as? [ImageLink] ?? [], parent: mod) { imageLink in
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
            
            LinksSection(mod: mod, editMode: $editMode) {
                ExternalLink(mod: mod, context: moc)
            } onDelete: { links in
                linkController.remove(links: links, from: mod, context: moc)
            }
            
            // Modules
            
            ModulesSection(mod: mod, deleteDisabled: !editMode) { module in
                guard let vc = vc else { return print("no vc") }
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let moduleDetailVC = storyboard.instantiateViewController(withIdentifier: "ModuleDetail") as! ModuleDetailTableViewController
                
                moduleDetailVC.gameReference = gameReference
                moduleDetailVC.moduleType = module.type
                moduleDetailVC.module = module
                
                vc.navigationController?.pushViewController(moduleDetailVC, animated: true)
            }
            
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
                                message: nil,
                                buttons: exportButtons,
                                ipadAndMacConfiguration: IpadAndMacConfiguration(anchor: nil, arrowEdge: nil),
                                normalButtonColor: UIColor.systemBlue)
                }
            }
        }
        .introspectViewController { vc in
            self.vc = vc
        }
        .toast(isPresenting: $showingLoading) {
            AlertToast(displayMode: .alert, type: .loading, title: "Generating QR Codes")
        }
        .navigationBarTitle(mod.name ?? "Mod")
        .navigationBarItems(trailing: editButton)
        .onDisappear {
            // This doesn't seem to be the best way to check this. When navigating
            // to a module, this is called. Instead, storing a property indicating
            // if there are changes to be saved could be better.
            // TODO: Update this
            if !self.presentationMode.wrappedValue.isPresented {
                self.modController.saveOrDeleteIfEmpty(self.mod, context: self.moc)
            }
        }
        .alert(item: $selectedIngredient) { ingredient in
            Alert(title: Text(ingredient.name ?? "Unknown ingredient"), message: Text("Plugin and FormID:\n\(ingredient.id ?? "")"))
        }
        .sheet(item: self.$qrCodes) { qrCodes in
            NavigationView {
                QRCodeView(name: mod.name, qrCodes: qrCodes)
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
    var selectModule: (Module) -> Void
    
    var body: some View {
        ForEach(types) { type in
            ModuleTypeSection(mod: mod, type: type, deleteDisabled: deleteDisabled, selectModule: selectModule)
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
    
    var mod: Mod
    var type: ModuleType
    var deleteDisabled: Bool
    var selectModule: (Module) -> Void
    
    init(mod: Mod, type: ModuleType, deleteDisabled: Bool, selectModule: @escaping (Module) -> Void) {
        self.mod = mod
        self.type = type
        self.deleteDisabled = deleteDisabled
        self.fetchRequest = FetchRequest(entity: Module.entity(), sortDescriptors: [], predicate: NSPredicate(format: "mod = %@ AND type = %@", mod, type))
        self.selectModule = selectModule
    }
    
    var body: some View {
        // Not sure if I'm crazy or if they changed the SwiftUI compiler,
        // but this Group doesn't actually need to be here.
        //TODO: Remove this Group
        Group {
            if modules.count > 0 {
                Section(header: Text(type.typeName.pluralize())) {
                    ForEach (modules) { module in
                        Button(module.name ?? "Unknown module") {
                            selectModule(module)
                        }
                        .foregroundColor(.primary)
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
