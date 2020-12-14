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
    var key: String { get }
    
    @discardableResult
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON, context: NSManagedObjectContext) throws -> Bool
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, from string: String, context: NSManagedObjectContext) throws
    func addRelationship<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, relationshipObject: RelationshipType, context: NSManagedObjectContext)
    func addRelationships<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON, context: NSManagedObjectContext) throws -> Bool
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches json: JSON) -> Bool
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches string: String) -> Bool
    func object<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(_ object: ObjectType, isRelatedTo relative: RelationshipType) -> Bool
    func json<FunctionType: NSManagedObject>(_ object: FunctionType) -> (relationshipJSON: JSON?, objectJSON: JSON?)
}

struct Relationship<ObjectType: NSManagedObject>: RelationshipProtocol {
    var key: String
    var orderedSet: Bool = false
    var createIfNotFound: Bool = false
    let jsonRepresentation: JSONRepresentation<ObjectType>
    
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON, context: NSManagedObjectContext) throws -> Bool {
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
    
    func addRelationships<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON, context: NSManagedObjectContext) throws -> Bool {
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
        return relationshipObject == relative
    }
    
    func json<FunctionType: NSManagedObject>(_ object: FunctionType) -> (relationshipJSON: JSON?, objectJSON: JSON?) {
        guard let relationship = object.value(forKey: key) else { return (nil, nil) }
        
        var relationshipJSON: JSON?
        var objectJSON: JSON?
        
        if let relationshipObject = relationship as? NSManagedObject,
            let id = relationshipObject.idString {
            relationshipJSON = JSON([key: id])
            
            if let relationshipObject = relationshipObject as? ObjectType {
                objectJSON = jsonRepresentation.json([relationshipObject])
            }
        }
        
        let relationshipObjects: [NSManagedObject]?
        
        if let set = relationship as? Set<NSManagedObject> {
            relationshipObjects = Array(set)
        } else if let orderedSet = relationship as? NSOrderedSet,
                  let array = orderedSet.array as? [NSManagedObject] {
            relationshipObjects = array
        } else {
            relationshipObjects = nil
        }
        
        if let relationshipObjects = relationshipObjects {
            var ids: [String] = []
            for object in relationshipObjects {
                guard let id = object.idString else { continue }
                ids.append(id)
            }
            
            relationshipJSON = JSON([key:ids])
            if let objects = relationshipObjects as? [ObjectType] {
                objectJSON = jsonRepresentation.json(Array(objects))
            }
        }
        
        return (relationshipJSON, objectJSON)
    }
}

struct RelationshipContainer {
    var relationship: RelationshipProtocol
    var exportObjects: Bool
    var required: Bool
    
    init(_ relationship: RelationshipProtocol, exportObjects: Bool = false, required: Bool = false) {
        self.relationship = relationship
        self.exportObjects = exportObjects
        self.required = required
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
    
    @discardableResult
    static func fetchAndImportAllObjects<ObjectType: NSManagedObject> (
        from json: JSON,
        jsonRepresentation rep: JSONRepresentation<ObjectType>,
        context: NSManagedObjectContext) throws -> [String] {
        var output: [String] = []
        
        if let objects = json[rep.arrayKey].array,
            objects.count > 0 {
            var allObjects = try self.allObjects(for: rep, context: context)
            
            objectsLoop: for objectJSON in objects {
                guard let object = getOrCreateObject(json: objectJSON, from: allObjects, idIsUUID: rep.idIsUUID, context: context) else { continue }
                
                importAttributes(with: rep.attributes, for: object, from: objectJSON)
                
                if let name = object.value(forKey: "name") as? String {
                    output.append(name)
                }
                
                for container in rep.toOneRelationships {
                    let objectFound = try container.relationship.addRelationship(to: object, json: objectJSON, context: context)
                    // Delete if a required relationship is not present
                    if container.required,
                       !objectFound {
                        context.delete(object)
                        continue objectsLoop
                    }
                }
                
                for container in rep.toManyRelationships {
                    let objectFound = try container.relationship.addRelationships(to: object, json: objectJSON, context: context)
                    // Delete if a required relationship is not present
                    if container.required,
                       !objectFound {
                        context.delete(object)
                        continue objectsLoop
                    }
                }
                
                for relationship in rep.relationshipObjects {
                    try relationship.addRelationship(to: object, json: objectJSON, context: context)
                }
                
                allObjects.append(object)
            }
            
            rep.allObjects = allObjects
        }
        
        return output
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
                return id.lowercased() == idString.lowercased()
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
    
    @discardableResult
    static func addRelationship<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, json: JSON, with relationship: Relationship<RelationshipType>, context: NSManagedObjectContext) throws -> Bool{
        
        let relationshipObjects = try allObjects(for: relationship.jsonRepresentation, context: context)
        
        guard let id = json[relationship.key].string,
            let relationshipObject = relationshipObjects.first(where: { relationshipObject -> Bool in
                
                let objectID = relationshipObject.value(forKey: "id")
                if let uuid = objectID as? UUID {
                    return uuid.uuidString.lowercased() == id.lowercased()
                } else if let idString = objectID as? String {
                    return idString.lowercased() == id.lowercased()
                }
                
                return false
            }) else { return false }
        
        object.setValue(relationshipObject, forKey: relationship.key)
        return true
    }
    
    static func addRelationships<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, json: JSON, with relationship: Relationship<RelationshipType>, context: NSManagedObjectContext) throws -> Bool {
        guard let idArray = json[relationship.key].array,
            idArray.count > 0 || relationship.createIfNotFound else { return false }
        
        let relationshipObjects = try allObjects(for: relationship.jsonRepresentation, context: context)
        
        var notEmpty = false
        
        for idJSON in idArray {
            guard let id = idJSON.string else { continue }
            let relationshipObject: RelationshipType
            
            if let existingRelationshipObject = relationshipObjects.first(where: { relationshipObject -> Bool in
                let objectID = relationshipObject.value(forKey: "id")
                if let uuid = objectID as? UUID {
                    return uuid.uuidString.lowercased() == id.lowercased()
                } else if let idString = objectID as? String {
                    return idString.lowercased() == id.lowercased()
                }
                
                return false
            }) {
                relationshipObject = existingRelationshipObject
            } else if relationship.createIfNotFound {
                let newRelationshipObject = RelationshipType(context: context)
                switch newRelationshipObject.entity.attributesByName["id"]?.attributeType {
                case .UUIDAttributeType:
                    guard let uuid = UUID(uuidString: id) else {
                        context.delete(newRelationshipObject)
                        continue
                    }
                    newRelationshipObject.setValue(uuid, forKey: "id")
                case .stringAttributeType:
                    newRelationshipObject.setValue(id, forKey: "id")
                default:
                    context.delete(newRelationshipObject)
                    continue
                }
                
                relationshipObject = newRelationshipObject
            } else {
                continue
            }
            
            if relationship.orderedSet {
                object.mutableOrderedSetValue(forKey: relationship.key).add(relationshipObject)
            } else {
                object.mutableSetValue(forKey: relationship.key).add(relationshipObject)
            }
            notEmpty = true
        }
        
        return notEmpty
    }
    
    static func object<ObjectType: NSManagedObject>(_ object: ObjectType, hasID id: String) -> Bool {
        guard let objectID = object.value(forKey: "id") else { return false }
        if let objectUUID = objectID as? UUID {
            return id == objectUUID.uuidString
        } else if let objectIDString = objectID as? String {
            return id.lowercased() == objectIDString.lowercased()
        }
        
        return false
    }
}
