//
//  ModuleTypeController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class ModuleTypeController {
    var types: [ModuleType] = []
    
    init() {
        do {
            let fetchRequest: NSFetchRequest<ModuleType> = ModuleType.fetchRequest()
            
            let allTypes = try CoreDataStack.shared.mainContext.fetch(fetchRequest)
            self.types = allTypes
        } catch {
            NSLog("Could not fetch module types: \(error)")
        }
    }
}
