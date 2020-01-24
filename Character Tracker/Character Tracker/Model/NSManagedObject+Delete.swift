//
//  NSManagedObject+Delete.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 1/23/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData

extension NSManagedObject {
    
    func deleteRelationshipObjects(forKey key: String, context: NSManagedObjectContext) {
        let objects = self.mutableSetValue(forKey: key)
        for object in objects {
            guard let object = object as? NSManagedObject else { continue }
            context.delete(object)
        }
    }
    
    func deleteRelationshipObjects(forKeys keys: [String], context: NSManagedObjectContext) {
        for key in keys {
            deleteRelationshipObjects(forKey: key, context: context)
        }
    }
    
    func deleteRelationshipObjects(forKey key: String, using predicate: NSPredicate, context: NSManagedObjectContext) {
        guard let objects = self.value(forKey: key) as? NSSet,
            let filteredObjects = objects.filtered(using: predicate) as? Set<NSManagedObject> else { return }
        
        for object in filteredObjects {
            context.delete(object)
        }
    }
    
}
