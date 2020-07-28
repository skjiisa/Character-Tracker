//
//  JSONController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 1/1/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData
import SwiftyJSON

protocol RelationshipProtocol {
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON, context: NSManagedObjectContext) throws
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, from string: String, context: NSManagedObjectContext) throws
    func addRelationship<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, relationshipObject: RelationshipType, context: NSManagedObjectContext)
    func addRelationships<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON, context: NSManagedObjectContext) throws
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches json: JSON) -> Bool
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches string: String) -> Bool
    func object<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(_ object: ObjectType, isRelatedTo relative: RelationshipType) -> Bool
    func json<ObjectType: NSManagedObject>(_ object: ObjectType) -> JSON?
}

struct Relationship<ObjectType: NSManagedObject>: RelationshipProtocol {
    let key: String
    let jsonRepresentation: JSONRepresentation<ObjectType>
    
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON, context: NSManagedObjectContext) throws {
        try JSONController.addRelationship(to: object, json: json, with: self, context: context)
    }
    
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, from string: String, context: NSManagedObjectContext) throws {
        let dictionary: [String: String] = [key: string]
        let json = JSON(dictionary)
        try JSONController.addRelationship(to: object, json: json, with: self, context: context)
    }
    
    func addRelationship<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, relationshipObject: RelationshipType, context: NSManagedObjectContext) {
        object.setValue(relationshipObject, forKey: key)
    }
    
    func addRelationships<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON, context: NSManagedObjectContext) throws {
        try JSONController.addRelationships(to: object, json: json, with: self, context: context)
    }
    
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches string: String) -> Bool {
        guard let relationshipObject = object.value(forKey: key) as? NSManagedObject else { return false }
        
        return JSONController.object(relationshipObject, hasID: string)
    }
    
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches json: JSON) -> Bool {
        guard let idString = json[key].string else { return false }
        
        return self.object(object, matches: idString)
    }
    
    func object<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(_ object: ObjectType, isRelatedTo relative: RelationshipType) -> Bool {
        guard let relationshipObject = object.value(forKey: key) as? RelationshipType else { return false }
        return relationshipObject == object
    }
    
    func json<ObjectType: NSManagedObject>(_ object: ObjectType) -> JSON? {
        guard let relationshipObject = object.value(forKey: key) as? NSManagedObject,
            let relationshipID = relationshipObject.value(forKey: "id") as? UUID else { return nil }
        
        var json = JSON([:])
        json[key].object = relationshipID.uuidString
        return json
    }
}

class JSONController {
    private init() {}
    
    static func allObjects<ObjectType: NSManagedObject>(for rep: JSONEntity<ObjectType>, context: NSManagedObjectContext) throws -> [ObjectType] {
        if let repObjects = rep.allObjects {
            return repObjects
        } else {
            let fetchRequest = ObjectType.fetchRequest() as! NSFetchRequest<ObjectType>
            return try context.fetch(fetchRequest)
        }
    }
    
    static func fetchAndImportAllObjects<ObjectType: NSManagedObject>(
        from json: JSON,
        jsonRepresentation rep: JSONRepresentation<ObjectType>,
        context: NSManagedObjectContext) throws {
        
        if let objects = json[rep.arrayKey].array,
            objects.count > 0 {
            var allObjects = try self.allObjects(for: rep, context: context)
            
            for objectJSON in objects {
                guard let object = getOrCreateObject(json: objectJSON, from: allObjects, idIsUUID: rep.idIsUUID, context: context) else { continue }
                
                importAttributes(with: rep.attributes, for: object, from: objectJSON)
                
                for relationship in rep.toOneRelationships {
                    try relationship.addRelationship(to: object, json: objectJSON, context: context)
                }
                
                for relationship in rep.toManyRelationships {
                    try relationship.addRelationships(to: object, json: objectJSON, context: context)
                }
                
                for relationship in rep.relationshipObjects {
                    try relationship.addRelationship(to: object, json: objectJSON, context: context)
                }
                
                allObjects.append(object)
            }
            
            rep.allObjects = allObjects
        }
    }
    
    // This could maybe be simplified using implicit conversions between Strings and UUIDs
    static private func getOrCreateObject<ObjectType: NSManagedObject>(json: JSON, from existingObjects: [ObjectType], idIsUUID: Bool = true, context: NSManagedObjectContext) -> ObjectType? {
        guard let idString = json["id"].string else { return nil }
        
        if idIsUUID {
            guard let uuid = UUID(uuidString: idString) else { return nil }
            
            if let existingObject = existingObjects.first(where: { existingObject -> Bool in
                guard let id = existingObject.value(forKey: "id") as? UUID else { return false }
                return id == uuid
            }) {
                return existingObject
            }
            
            let object = ObjectType(context: context)
            object.setValue(uuid, forKey: "id")
            return object
        } else {
            if let existingObject = existingObjects.first(where: { existingObject -> Bool in
                guard let id = existingObject.value(forKey: "id") as? String else { return false }
                return id == idString
            }) {
                return existingObject
            }
            
            let object = ObjectType(context: context)
            object.setValue(idString, forKey: "id")
            return object
        }
    }
    
    static func importAttributes<ObjectType: NSManagedObject>(with keys: [String], for object: ObjectType, from json: JSON) {
        for key in keys {
            let value = json[key].object
            if value is NSNull { continue }
            object.setValue(value, forKey: key)
        }
    }
    
    static func addRelationship<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, json: JSON, with relationship: Relationship<RelationshipType>, context: NSManagedObjectContext) throws {
        
        let relationshipObjects = try allObjects(for: relationship.jsonRepresentation, context: context)
        
        guard let id = json[relationship.key].string,
            let relationshipObject = relationshipObjects.first(where: { relationshipObject -> Bool in
                
                let objectID = relationshipObject.value(forKey: "id")
                if let uuid = objectID as? UUID {
                    return uuid.uuidString == id
                } else if let idString = objectID as? String {
                    return idString == id
                }
                
                return false
            }) else { return }
        
        object.setValue(relationshipObject, forKey: relationship.key)
    }
    
    static func addRelationships<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, json: JSON, with relationship: Relationship<RelationshipType>, context: NSManagedObjectContext) throws {
        guard let idArray = json[relationship.key].array,
            idArray.count > 0 else { return }
        
        let relationshipsSet = object.mutableSetValue(forKey: relationship.key)
        let relationshipObjects = try allObjects(for: relationship.jsonRepresentation, context: context)
        
        for idJSON in idArray {
            guard let id = idJSON.string,
                let relationshipObject = relationshipObjects.first(where: { relationshipObject -> Bool in
                    guard let uuid = relationshipObject.value(forKey: "id") as? UUID else { return false }
                    return uuid.uuidString == id
            }) else { continue }
            
            relationshipsSet.add(relationshipObject)
        }
    }
    
    static func object<ObjectType: NSManagedObject>(_ object: ObjectType, hasID id: String) -> Bool {
        guard let objectID = object.value(forKey: "id") else { return false }
        if let objectUUID = objectID as? UUID {
            return id == objectUUID.uuidString
        } else if let objectIDString = objectID as? String {
            return id == objectIDString
        }
        
        return false
    }
}
