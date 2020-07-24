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
    func clearFilter()
    func dismiss()
    var requireAllAttributes: Bool { get set }
}

struct ModulesFilterForm: View {
    @FetchRequest(entity: ModuleType.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]) var moduleTypes: FetchedResults<ModuleType>
    var attributesFetchRequest: FetchRequest<Attribute>
    var attributes: FetchedResults<Attribute> {
        attributesFetchRequest.wrappedValue
    }
    @State var checkedTypes: Set<ModuleType>
    @State var checkedAttributes: Set<Attribute>
    @Binding var requireAllAttributes: Bool
    
    let showTypes: Bool
    weak var delegate: ModulesFilterFormDelegate?
    
    init(type: ModuleType? = nil, checkedTypes: Set<ModuleType>? = nil, checkedAttributes: Set<Attribute>? = nil, requireAllAttributes: Bool = true, delegate: ModulesFilterFormDelegate? = nil) {
        if let checkedTypes = checkedTypes {
            _checkedTypes = .init(initialValue: checkedTypes)
        } else {
            _checkedTypes = .init(initialValue: Set<ModuleType>())
        }
        if let checkedAttributes = checkedAttributes {
            _checkedAttributes = .init(initialValue: checkedAttributes)
        } else {
            _checkedAttributes = .init(initialValue: Set<Attribute>())
        }
        _requireAllAttributes = .init(get: {
            delegate?.requireAllAttributes ?? true
        }, set: { value in
            delegate?.requireAllAttributes = value
        })
        self.delegate = delegate
        
        showTypes = type == nil
        
        let predicate: NSPredicate?
        if let type = type {
            predicate = NSPredicate(format: "ANY modules.module.type = %@", type)
        } else {
            predicate = NSPredicate(format: "ANY modules != nil")
        }
        attributesFetchRequest = FetchRequest(entity: Attribute.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: predicate)
    }
    
    //MARK: Views
    
    var cancelButton: some View {
        Button("Cancel") {
            self.delegate?.clearFilter()
            self.delegate?.dismiss()
        }
    }
    
    var doneButton: some View {
        Button("Done") {
            self.delegate?.dismiss()
        }
    }
    
    //MARK: Body
    
    var body: some View {
        Form {
            if showTypes && moduleTypes.count > 0 {
                SwiftUI.Section(header: Text("Type")) {
                    ForEach(moduleTypes, id: \.self) { moduleType in
                        Button(action: {
                            self.delegate?.toggle(moduleType)
                            self.checkedTypes.formSymmetricDifference([moduleType])
                        }) {
                            HStack {
                                Text(moduleType.name ?? "Module Type")
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
            
            if attributes.count > 0 {
                SwiftUI.Section(header: Text("Attributes")) {
                    Toggle("Require all of the below", isOn: $requireAllAttributes)
                    
                    ForEach(attributes, id: \.self) { attribute in
                        Button(action: {
                            self.delegate?.toggle(attribute)
                            self.checkedAttributes.formSymmetricDifference([attribute])
                        }) {
                            HStack {
                                Text(attribute.name ?? "Attribute")
                                    .foregroundColor(.primary)
                                if self.checkedAttributes.contains(attribute) {
                                    Spacer()
                                    SwiftUI.Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Filter Modules")
        .navigationBarItems(leading: cancelButton, trailing: doneButton)
    }
}

struct ModulesFilterForm_Previews: PreviewProvider {
    static var previews: some View {
        ModulesFilterForm()
    }
}
