//
//  ModulesView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ModulesView: View {
    @FetchRequest(entity: Module.entity(), sortDescriptors: []) var modules: FetchedResults<Module>
    
    var didSelect: (Module) -> Void
    
    init(didSelect: @escaping (Module) -> Void = {_ in}) {
        self.didSelect = didSelect
    }
    
    var body: some View {
        List {
            ForEach(modules, id: \.self) { module in
                Button(action: {
                    self.didSelect(module)
                }) {
                    Text(module.name ?? "Unknown module")
                }
            }
        }
    }
}

struct ModulesView_Previews: PreviewProvider {
    static var previews: some View {
        ModulesView()
    }
}
