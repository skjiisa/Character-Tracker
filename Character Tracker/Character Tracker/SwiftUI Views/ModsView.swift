//
//  ModsView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ModsView: View {
    
    //MARK: Properties
    
    @Environment(\.managedObjectContext) var moc
    var fetchRequest: FetchRequest<Mod>
    var mods: FetchedResults<Mod> {
        fetchRequest.wrappedValue
    }
    
    @EnvironmentObject var modController: ModController
    @EnvironmentObject var gameReference: GameReference
    var moduleController = ModuleController()
    var ingredientController = IngredientController()
    
    @State private var newMod: Mod?
    @State private var deleteMod: Mod?
    @State private var alert: Alert?
    @State private var showingScanner = false
    @State private var showingAlert: AlertContainer?
    
    init(game: Game?) {
        var predicate: NSPredicate?
        if let game = game {
            predicate = NSPredicate(format: "%@ in games", game)
        }
        self.fetchRequest = FetchRequest(entity: Character_Tracker.Mod.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: predicate)
    }
    
    //MARK: Views
    
    var newModButton: some View {
        Button {
            guard let game = gameReference.game else { return }
            let newMod = modController.create(game: game, context: moc)
            self.newMod = newMod
        } label: {
            Image(systemName: "plus")
                .imageScale(.large)
        }
    }
    
    var scannerButton: some View {
        Button {
            showingScanner = true
        } label: {
            Image(systemName: "qrcode.viewfinder")
                .imageScale(.large)
        }
        .sheet(isPresented: $showingScanner) {
            // alert is set from the ScannerView binding, but it is set too fast,
            // before this sheet is dismissed, so the alert item needs to be set
            // after the sheet is dismissed.
            guard let alert = alert else { return }
            showingAlert = AlertContainer(alert)
        } content: {
            ScannerNavigationView(showing: $showingScanner, alert: $alert)
        }
        .alert(item: $showingAlert) { alertContainer -> Alert in
            alertContainer.alert
        }
    }
    
    var buttonsView: some View {
        HStack {
            scannerButton
            newModButton
                .padding(.leading)
        }
    }
    
    //MARK: Body
    
    var body: some View {
        List {
            ForEach(mods, id: \.self) { mod in
                NavigationLink(mod.wrappedName, destination: ModDetailView(mod: mod)
                                .environment(\.managedObjectContext, moc)
                                .environmentObject(modController)
                                .environmentObject(gameReference)
                )
            }
            .onDelete { indexSet in
                let mod = self.mods[indexSet.first!]
                self.deleteMod = mod
            }
            .actionSheet(item: $deleteMod) { mod in
                ActionSheet(title: Text("Delete" + (mod.name ?? "mod")), message: Text("Keep \(mod.name ?? "mod") contents (modules, ingredients)?"), buttons: [
                    .cancel(),
                    .default(Text("Keep contents"), action: {
                        self.modController.delete(mod: mod, context: self.moc)
                    }),
                    .destructive(Text("Delete all"), action: {
                        self.moduleController.deleteAllModules(from: mod, context: self.moc)
                        self.ingredientController.removeOrDeleteAllIngredients(from: mod, context: self.moc)
                        self.modController.delete(mod: mod, context: self.moc)
                    })
                ])
            }
        }
        .navigationBarTitle("Mods")
        .navigationBarItems(trailing: buttonsView)
        .sheet(item: $newMod) { mod in
            NavigationView {
                ModDetailView(mod: mod, editMode: true)
                    .environment(\.managedObjectContext, self.moc)
                    .environmentObject(self.modController)
                    .environmentObject(gameReference)
            }
        }
    }
}

//MARK: Previews

struct ModsView_Previews: PreviewProvider {
    static var previews: some View {
        ModsView(game: nil).environmentObject(ModController())
    }
}
