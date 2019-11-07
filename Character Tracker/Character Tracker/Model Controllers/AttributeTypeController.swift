//
//  AttributeTypeController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/6/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class AttributeTypeController {
    var types: [AttributeType] = []

    init() {
        do {
            let fetchRequest: NSFetchRequest<AttributeType> = AttributeType.fetchRequest()
            
            let allTypes = try CoreDataStack.shared.mainContext.fetch(fetchRequest)
            self.types = allTypes
        } catch {
            NSLog("Could not fetch attribute types: \(error)")
        }
    }
}
