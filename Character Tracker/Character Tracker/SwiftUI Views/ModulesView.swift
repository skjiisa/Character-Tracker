//
//  ModulesView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ModulesView: View {
    @FetchRequest(entity: Module.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]) var modules: FetchedResults<Module>
    
    var didSelect: (Module) -> Void
    var character: Character?
    var module: Module?
    
    init(didSelect: @escaping (Module) -> Void = {_ in}) {
        self.didSelect = didSelect
    }
    
    init(character: Character, didSelect: @escaping (Module) -> Void = {_ in}) {
        self.character = character
        self.didSelect = didSelect
    }
    
    init(module: Module, didSelect: @escaping (Module) -> Void = {_ in}) {
        self.module = module
        self.didSelect = didSelect
    }
    
    var body: some View {
        List {
            ForEach(modules, id: \.self) { module in
                Button(action: {
                    self.didSelect(module)
                }) {
                    HStack {
                        Text(module.name ?? "Unknown module")
                        if self.character?.modules?.contains(where: { ($0 as? CharacterModule)?.module == module }) ?? false
                            || self.module?.children?.contains(where: { ($0 as? ModuleModule)?.child == module }) ?? false {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(Font.body.bold())
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationBarTitle("Modules")
    }
}

struct ModulesView_Previews: PreviewProvider {
    static var previews: some View {
        ModulesView()
    }
}
