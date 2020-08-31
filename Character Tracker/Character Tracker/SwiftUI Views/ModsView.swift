//
//  ModsView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ModsView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: Character_Tracker.Mod.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: false)]) var mods: FetchedResults<Mod>
    
    @EnvironmentObject var modController: ModController
    var moduleController = ModuleController()
    
    @State private var newMod: Mod?
    @State private var deleteMod: Mod?
    @State private var alert: Alert?
    @State private var showingScanner = false
    @State private var showingAlert: AlertContainer?
    
    var newModButton: some View {
        Button(action: {
            let newMod = self.modController.create(context: self.moc)
            self.newMod = newMod
        }) {
            Image(systemName: "plus")
                .imageScale(.large)
        }
    }
    
    var scannerButton: some View {
        Button(action: {
            self.showingScanner = true
        }) {
            Image(systemName: "qrcode.viewfinder")
                .imageScale(.large)
        }
        .sheet(isPresented: $showingScanner, onDismiss: {
            // alert is set from the ScannerView binding, but it is set too fast,
            // before this sheet is dismissed, so the alert item needs to be set
            // after the sheet is dismissed.
            guard let alert = self.alert else { return }
            self.showingAlert = AlertContainer(alert)
        }) {
            ScannerView(showing: self.$showingScanner, alert: self.$alert)
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
    
    var body: some View {
        List {
            ForEach(mods, id: \.self) { mod in
                NavigationLink(destination:
                    ModDetailView(mod: mod)
                        .environment(\.managedObjectContext, self.moc)
                        .environmentObject(self.modController)) {
                            Text(mod.name ?? "")
                }
            }
            .onDelete { indexSet in
                let mod = self.mods[indexSet.first!]
                self.deleteMod = mod
            }
        }
        .navigationBarTitle("Mods")
        .navigationBarItems(trailing: buttonsView)
        .sheet(item: $newMod) { mod in
            NavigationView {
                ModDetailView(mod: mod)
                    .environment(\.managedObjectContext, self.moc)
                    .environmentObject(self.modController)
            }
        }
        .actionSheet(item: $deleteMod) { mod in
            ActionSheet(title: Text("Delete" + (mod.name ?? "mod")), message: Text("Keep \(mod.name ?? "mod") contents (modules, ingredients)?"), buttons: [
                .cancel(),
                .default(Text("Keep contents"), action: {
                    self.modController.delete(mod: mod, context: self.moc)
                }),
                .destructive(Text("Delete all"), action: {
                    self.moduleController.deleteAllModules(from: mod, context: self.moc)
                    self.modController.delete(mod: mod, context: self.moc)
                })
            ])
        }
    }
}

struct ModsView_Previews: PreviewProvider {
    static var previews: some View {
        ModsView().environmentObject(ModController())
    }
}
