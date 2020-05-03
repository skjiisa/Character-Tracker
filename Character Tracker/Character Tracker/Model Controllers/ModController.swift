//
//  ModController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData

class ModController: ObservableObject {
    
    @discardableResult func create(mod name: String, context: NSManagedObjectContext) -> Mod {
        let mod = Mod(context: context)
        mod.name = name
        CoreDataStack.shared.save(context: context)
        return mod
    }
    
    func delete(mod: Mod, context: NSManagedObjectContext) {
        // delete relationship objects
        context.delete(mod)
        CoreDataStack.shared.save(context: context)
    }
    
}
