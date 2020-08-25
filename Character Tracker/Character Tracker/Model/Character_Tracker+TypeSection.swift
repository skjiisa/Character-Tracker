//
//  Character_Tracker+TypeSection.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import Foundation

extension AttributeTypeSection: TypeSection {
    var typeName: String {
        if let typeName = self.type?.name {
            return typeName
        }
        
        return ""
    }
}

extension ModuleType: TypeSection {
    var typeName: String {
        if let typeName = self.name {
            return typeName
        }
        
        return ""
    }
}
