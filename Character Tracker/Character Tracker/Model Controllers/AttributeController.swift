//
//  attributeController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

enum AttributeTypeKeys: String, CaseIterable {
    case skill
    case objective
}

class AttributeController {
    
    func create(attribute name: String, vanilla: Bool, game: Game, type: AttributeType, context: NSManagedObjectContext) {
        Attribute(name: name, vanilla: vanilla, game: game, type: type, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
    func edit(attribute: Attribute, name: String, context: NSManagedObjectContext) {
        attribute.name = name
        CoreDataStack.shared.save(context: context)
    }
    
    func type(_ type: AttributeTypeKeys) -> AttributeType? {
        do {
            let fetchRequest: NSFetchRequest<AttributeType> = AttributeType.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", type.rawValue)
            
            let types = try CoreDataStack.shared.mainContext.fetch(fetchRequest)
            
            if types.count > 0 {
                return types[0]
            } else {
                return nil
            }
        } catch {
            NSLog("Could not fetch attribute type: \(error)")
            return nil
        }
    }
    
}
