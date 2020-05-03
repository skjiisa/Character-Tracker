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
    @FetchRequest(entity: Mod.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: false)]) var mods: FetchedResults<Mod>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(mods, id: \.self) { mod in
                    Text(mod.name ?? "")
                }
            }
            .navigationBarTitle("Mods")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ModsView_Previews: PreviewProvider {
    static var previews: some View {
        ModsView()
    }
}
