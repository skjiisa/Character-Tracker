//
//  ModulesFilterForm.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 7/23/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

protocol ModulesFilterFormDelegate: class {
    func toggle(_: ModuleType)
    func toggle(_: Attribute)
}

struct ModulesFilterForm: View {
    @FetchRequest(entity: ModuleType.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]) var moduleTypes: FetchedResults<ModuleType>
    
    let attributes: [Attribute]
    let showTypes: Bool
    weak var delegate: ModulesFilterFormDelegate?
    
    init(modules: [Module]?, showTypes: Bool, delegate: ModulesFilterFormDelegate? = nil) {
        self.delegate = delegate
        
        var attributesSet = Set<Attribute>()
        (modules ?? []).forEach { module in
            guard let moduleAttributes = module.attributes as? Set<ModuleAttribute> else { return }
            attributesSet.formUnion(moduleAttributes.compactMap { $0.attribute })
        }
        self.attributes = attributesSet.sorted(by: { $0.name ?? "" > $1.name ?? "" })
        
        self.showTypes = showTypes
    }
    
    var body: some View {
        Form {
            if showTypes && moduleTypes.count > 0 {
                SwiftUI.Section(header: Text("Type")) {
                    ForEach(moduleTypes, id: \.self) { moduleType in
                        Button(moduleType.name ?? "Module Type") {
                            self.delegate?.toggle(moduleType)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            
            if attributes.count > 0 {
                SwiftUI.Section(header: Text("Attributes")) {
                    ForEach(attributes, id: \.self) { attribute in
                        Button(attribute.name ?? "Attribute") {
                            self.delegate?.toggle(attribute)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationBarTitle("Filter Modules")
    }
}

struct ModulesFilterForm_Previews: PreviewProvider {
    static var previews: some View {
        ModulesFilterForm(modules: [], showTypes: true)
    }
}
