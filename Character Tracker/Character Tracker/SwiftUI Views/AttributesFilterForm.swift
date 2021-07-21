//
//  AttributesFilterForm.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 7/24/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

protocol AttributesFilterFormDelegate: AnyObject {
    func toggle(_: AttributeType)
    func clearFilter()
    func dismiss()
}

struct AttributesFilterForm: View {
    
    let checkedTypes: Set<AttributeType>?
    weak var delegate: AttributesFilterFormDelegate?
    
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
            TypeFilterSection<AttributeType>(checkedTypes: checkedTypes, toggle: delegate?.toggle(_:))
        }
        .navigationBarTitle("Filter Modules")
        .navigationBarItems(leading: cancelButton, trailing: doneButton)
    }
}

struct AttributesFilterForm_Previews: PreviewProvider {
    static var previews: some View {
        AttributesFilterForm(checkedTypes: nil)
    }
}
