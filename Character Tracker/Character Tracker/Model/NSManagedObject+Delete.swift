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
    
}
