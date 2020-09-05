//
//  ModulesView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ModulesView: View {
    var fetchRequest: FetchRequest<Module>
    var modules: FetchedResults<Module> {
        fetchRequest.wrappedValue
    }
    
    var didSelect: (Module) -> Void
    var type: ModuleType?
    var character: Character?
    var module: Module?
    
    var typeName: String {
        // This computed property only exists because, for some reason, putting
        // this directly in navigationBarTitle would crash the compiler.
        type?.name ?? "Module"
    }
    
    init(type: ModuleType? = nil, didSelect: @escaping (Module) -> Void = {_ in}) {
        self.type = type
        self.didSelect = didSelect
        
        var predicate: NSPredicate?
        if let type = type {
            predicate = NSPredicate(format: "type == %@", type)
        }
        
        self.fetchRequest = FetchRequest(entity: Module.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: predicate)
    }
    
    init(type: ModuleType? = nil, character: Character, didSelect: @escaping (Module) -> Void = {_ in}) {
        self.init(type: type, didSelect: didSelect)
        self.character = character
    }
    
    init(type: ModuleType? = nil, module: Module, didSelect: @escaping (Module) -> Void = {_ in}) {
        self.init(type: type, didSelect: didSelect)
        self.module = module
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
        .navigationBarTitle(typeName.pluralize())
    }
}

struct ModulesView_Previews: PreviewProvider {
    static var previews: some View {
        ModulesView()
    }
}
