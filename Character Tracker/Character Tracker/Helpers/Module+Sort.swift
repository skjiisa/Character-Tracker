//
//  Module+Sort.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import Foundation

extension Array where Element == Module {
    func sortedByLevel() -> [Module] {
        return modulesSortedByLevel(self)
    }
}

extension Set where Element == Module {
    func sortedByLevel() -> [Module] {
        return modulesSortedByLevel(self)
    }
}

fileprivate func modulesSortedByLevel<T: Sequence>(_ modules: T) -> [Module] where T.Element == Module {
    return modules.sorted(by: { module1, module2 -> Bool in
        // Modules with no level will be sorted to the end of the list
        // Modules with no level are stored as level 0
        // In order to sort level 0 modules to the end of the list, modules with level 0 are tested as if they are 1 level higher than the other module
        // If both modules are the same level (including if they're both 0), they will be sorted by name
        
        let module1Level: Int16
        
        if module1.level == 0 {
            module1Level = module2.level + 1
        } else {
            module1Level = module1.level
        }
        
        let module2Level: Int16
        
        if module2.level == 0 {
            module2Level = module1.level + 1
        } else {
            module2Level = module2.level
        }
        
        if module1Level > module2Level {
            return false
        } else if module2Level > module1Level {
            return true
        }
        
        if let module1Name = module1.name,
            let module2Name = module2.name {
            return module1Name < module2Name
        }
        
        return true
    })
}
