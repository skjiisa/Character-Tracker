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
    func addRelationships<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON)
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON)
}

struct Relationship<ObjectType: NSManagedObject>: RelationshipProtocol {
    let key: String
    let allObjects: [ObjectType]
    
    func addRelationship<ObjectType>(to object: ObjectType, json: JSON) where ObjectType : NSManagedObject {
        JSONController.addRelationship(to: object, json: json, with: key, from: allObjects)
    }
    
    func addRelationships<ObjectType>(to object: ObjectType, json: JSON) where ObjectType : NSManagedObject {
        JSONController.addRelationships(to: object, json: json, with: key, from: allObjects)
    }
}

class JSONController {
    
    static func preloadData() {
        let context = CoreDataStack.shared.mainContext
        
        do {
            let preloadDataURL = Bundle.main.url(forResource: "Preload", withExtension: "json")!
            let preloadData = try Data(contentsOf: preloadDataURL)
            let importJSON = try JSON(data: preloadData)
            
            // Import Games
            
            let allGames: [Game] = try fetchAndImportAllObjects(
                from: importJSON,
                arrayKey: "games",
                attributes: ["name", "index", "mainline"],
                context: context)
            
            // Import Attribute Types
            
            let allAttributeTypes: [AttributeType] = try fetchAndImportAllObjects(
                from: importJSON,
                arrayKey: "attribute_types",
                attributes: ["name"],
                context: context)
            
            // Import Attribute Type Sections
            
            let attributeTypesRelationship = Relationship(key: "type", allObjects: allAttributeTypes)
            let _: [AttributeTypeSection] = try fetchAndImportAllObjects(
                from: importJSON,
                arrayKey: "attribute_type_sections",
                attributes: ["name", "maxPriority", "minPriority"],
                toOneRelationships: [attributeTypesRelationship],
                context: context)
            
            // Import Module Types
            
            let _: [ModuleType] = try fetchAndImportAllObjects(
                from: importJSON,
                arrayKey: "module_types",
                attributes: ["name"],
                context: context)
            
            // Import Races
            
            let gamesRelationship = Relationship(key: "games", allObjects: allGames)
            let allRaces: [Race] = try fetchAndImportAllObjects(
                from: importJSON,
                arrayKey: "races",
                attributes: ["name"],
                toManyRelationships: [gamesRelationship],
                context: context)
            
            // Import Characters
            
            let raceRelationship = Relationship(key: "race", allObjects: allRaces)
            let gameRelationship = Relationship(key: "game", allObjects: allGames)
            let _: [Character] = try fetchAndImportAllObjects(
                from: importJSON,
                arrayKey: "characters",
                attributes: ["female", "name"],
                toOneRelationships: [raceRelationship, gameRelationship],
                context: context)
            
            CoreDataStack.shared.save(context: context)
        } catch {
            NSLog("\(error)")
        }
    }
    
    static private func fetchAndImportAllObjects<ObjectType: NSManagedObject>(
        from json: JSON,
        arrayKey: String,
        attributes: [String],
        toOneRelationships: [RelationshipProtocol] = [],
        toManyRelationships: [RelationshipProtocol] = [],
        context: NSManagedObjectContext) throws -> [ObjectType] {
        
        let fetchRequest = ObjectType.fetchRequest() as! NSFetchRequest<ObjectType>
        var allObjects = try context.fetch(fetchRequest)
        
        if let objects = json[arrayKey].array {
            for objectJSON in objects {
                guard let object = getOrCreateObject(json: objectJSON, from: allObjects, context: context) else { continue }
                
                importAttributes(with: attributes, for: object, from: objectJSON)
                
                for requirement in toOneRelationships {
                    requirement.addRelationship(to: object, json: objectJSON)
                }
                
                for requirement in toManyRelationships {
                    requirement.addRelationships(to: object, json: objectJSON)
                }
                
                allObjects.append(object)
            }
        }
        
        return allObjects
    }
    
    static private func getOrCreateObject<ObjectType: NSManagedObject>(json: JSON, from existingObjects: [ObjectType], context: NSManagedObjectContext) -> ObjectType? {
        guard let idString = json["id"].string,
            let uuid = UUID(uuidString: idString) else { return nil }
        
        if let existingObject = existingObjects.first(where: { existingObject -> Bool in
            guard let id = existingObject.value(forKey: "id") as? UUID else { return false }
            return id == uuid
        }) {
            return existingObject
        }
        
        let object = ObjectType(context: context)
        object.setValue(uuid, forKey: "id")
        return object
    }
    
    static private func importAttributes<ObjectType: NSManagedObject>(with keys: [String], for object: ObjectType, from json: JSON) {
        for key in keys {
            let value = json[key].object
            if value is NSNull { continue }
            object.setValue(value, forKey: key)
        }
    }
    
    static func addRelationship<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, json: JSON, with key: String, from relationshipObjects: [RelationshipType]) {
        guard let id = json[key].string,
            let relationshipObject = relationshipObjects.first(where: { relationshipObject -> Bool in
            guard let uuid = relationshipObject.value(forKey: "id") as? UUID else { return false }
            return uuid.uuidString == id
        }) else { return }
        
        object.setValue(relationshipObject, forKey: key)
    }
    
    static func addRelationships<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, json: JSON, with key: String, from relationshipObjects: [RelationshipType]) {
        let relationshipsSet = object.mutableSetValue(forKey: key)
        
        guard let idArray = json[key].array else { return }
        for idJSON in idArray {
            guard let id = idJSON.string,
                let relationshipObject = relationshipObjects.first(where: { relationshipObject -> Bool in
                    guard let uuid = relationshipObject.value(forKey: "id") as? UUID else { return false }
                    return uuid.uuidString == id
            }) else { continue }
            
            relationshipsSet.add(relationshipObject)
        }
    }
}
