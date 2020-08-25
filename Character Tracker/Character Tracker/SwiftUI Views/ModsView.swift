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
    
    @State private var newMod: Mod?
    
    var newModButton: some View {
        Button(action: {
            let newMod = self.modController.create(context: self.moc)
            self.newMod = newMod
        }) {
            Image(systemName: "plus")
                .imageScale(.large)
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
                self.modController.delete(mod: mod, context: self.moc)
            }
        }
        .navigationBarTitle("Mods")
        .navigationBarItems(trailing: newModButton)
        .sheet(item: $newMod) { mod in
            NavigationView {
                ModDetailView(mod: mod)
                    .environment(\.managedObjectContext, self.moc)
                    .environmentObject(self.modController)
            }
        }
    }
}

struct ModsView_Previews: PreviewProvider {
    static var previews: some View {
        ModsView().environmentObject(ModController())
    }
}
