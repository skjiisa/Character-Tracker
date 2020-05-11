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
    
    @State private var showingNewMod = false
    
    var newModButton: some View {
        Button(action: {
            self.showingNewMod = true
        }) {
            SwiftUI.Image(systemName: "plus")
                .imageScale(.large)
        }
    }
    
    var deleteAllButton: some View {
        Button(action: {
            for mod in self.mods {
                self.moc.delete(mod)
            }
        }) {
            Text("Delete all")
        }
    }
    
    var body: some View {
        NavigationView {
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
                    self.modController.delete(mod: mod, context: self.moc)
                }
            }
            .navigationBarTitle("Mods")
            .navigationBarItems(leading: deleteAllButton, trailing: newModButton)
            .sheet(isPresented: $showingNewMod) {
                NavigationView {
                    ModDetailView()
                        .environment(\.managedObjectContext, self.moc)
                        .environmentObject(self.modController)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ModsView_Previews: PreviewProvider {
    static var previews: some View {
        ModsView().environmentObject(ModController())
    }
}
