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
        self.sorted(by: moduleSort)
    }
}

extension Set where Element == Module {
    func sortedByLevel() -> [Module] {
        self.sorted(by: moduleSort)
    }
}

extension Set where Element == CharacterModule {
    func sortedByLevel() -> [CharacterModule] {
        self.sorted(by: {moduleSort(module1: $0.module, module2: $1.module)})
    }
}

fileprivate func moduleSort(module1: Module?, module2: Module?) -> Bool {
    // Modules with no level will be sorted to the end of the list
    // Modules with no level are stored as level 0
    // In order to sort level 0 modules to the end of the list, modules with level 0 are tested as if they are 1 level higher than the other module
    // If both modules are the same level (including if they're both 0), they will be sorted by name
    
    guard let module1 = module1,
        let module2 = module2 else { return true }
    
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
}
