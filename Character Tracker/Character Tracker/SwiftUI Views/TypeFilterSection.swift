//
//  TypeFilterSection.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 7/24/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI
import CoreData

struct TypeFilterSection<Entity: NamedEntity>: View {
    @FetchRequest(entity: Entity.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]) var types: FetchedResults<Entity>
    @State private var checkedTypes: Set<Entity>
    
    let toggle: ((Entity) -> Void)?
    
    init(checkedTypes: Set<Entity>? = nil, toggle: ((Entity) -> Void)? = nil) {
        _checkedTypes = .init(initialValue: checkedTypes ?? Set<Entity>())
        self.toggle = toggle
    }
    
    var body: some View {
        SwiftUI.Section(header: Text("Type")) {
            ForEach(types, id: \.self) { moduleType in
                Button(action: {
                    self.toggle?(moduleType)
                    self.checkedTypes.formSymmetricDifference([moduleType])
                }) {
                    HStack {
                        Text(moduleType.name ?? "Type")
                            .foregroundColor(.primary)
                        if self.checkedTypes.contains(moduleType) {
                            Spacer()
                            SwiftUI.Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}

struct TypeFilterForm_Previews: PreviewProvider {
    static var previews: some View {
        TypeFilterSection<ModuleType>()
    }
}

