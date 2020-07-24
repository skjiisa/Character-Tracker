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
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON)
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, from string: String)
    func addRelationships<ObjectType: NSManagedObject>(to object: ObjectType, json: JSON)
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches json: JSON) -> Bool
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches string: String) -> Bool
}

struct Relationship<ObjectType: NSManagedObject>: RelationshipProtocol {
    let key: String
    let allObjects: [ObjectType]
    
    func addRelationship<ObjectType>(to object: ObjectType, json: JSON) where ObjectType : NSManagedObject {
        JSONController.addRelationship(to: object, json: json, with: key, from: allObjects)
    }
    
    func addRelationship<ObjectType: NSManagedObject>(to object: ObjectType, from string: String) {
        let dictionary: [String: String] = [key: string]
        let json = JSON(dictionary)
        JSONController.addRelationship(to: object, json: json, with: key, from: allObjects)
    }
    
    func addRelationships<ObjectType>(to object: ObjectType, json: JSON) where ObjectType : NSManagedObject {
        JSONController.addRelationships(to: object, json: json, with: key, from: allObjects)
    }
    
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches string: String) -> Bool {
        guard let relationshipObject = object.value(forKey: key) as? NSManagedObject else { return false }
        
        return JSONController.object(relationshipObject, hasID: string)
    }
    
    func object<ObjectType: NSManagedObject>(_ object: ObjectType, matches json: JSON) -> Bool {
        guard let idString = json[key].string else { return false }
        
        return self.object(object, matches: idString)
    }
}

class JSONController {
    
    static func preloadData() {
        let importFiles = [
            "Preload",
            "Questlines"
        ]
        
        for file in importFiles {
            do {
                guard let preloadDataURL = Bundle.main.url(forResource: file, withExtension: "json") else {
                    NSLog("File not found: \(file).json")
                    continue
                }
                let preloadData = try Data(contentsOf: preloadDataURL)
                let importJSON = try JSON(data: preloadData)
                try loadData(json: importJSON, context: CoreDataStack.shared.mainContext)
            } catch {
                NSLog("\(error)")
            }
        }
    }
    
    static func loadData(json importJSON: JSON, context: NSManagedObjectContext) throws {
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
        
        // Import Attributes
        
        let gamesRelationship = Relationship(key: "games", allObjects: allGames)
        let allAttributes: [Attribute] = try fetchAndImportAllObjects(
            from: importJSON,
            arrayKey: "attributes",
            attributes: ["name"],
            toOneRelationships: [attributeTypesRelationship],
            toManyRelationships: [gamesRelationship],
            context: context)
        
        // Import Module Types
        
        let allModuleTypes: [ModuleType] = try fetchAndImportAllObjects(
            from: importJSON,
            arrayKey: "module_types",
            attributes: ["name"],
            context: context)
        
        // Import Ingredients
        
        let allIngredients: [Ingredient] = try fetchAndImportAllObjects(
            from: importJSON,
            arrayKey: "ingredients",
            attributes: ["name"],
            toManyRelationships: [gamesRelationship],
            idIsUUID: false,
            context: context)
        
        // Import Modules
        
        let moduleTypesRelationship = Relationship(key: "type", allObjects: allModuleTypes)
        let allModules: [Module] = try fetchAndImportAllObjects(
            from: importJSON,
            arrayKey: "modules",
            attributes: ["name", "level", "notes"],
            toOneRelationships: [moduleTypesRelationship],
            toManyRelationships: [gamesRelationship],
            context: context)
        
        // Import Module Ingredients
        
        let ingredientRelationship = Relationship(key: "ingredient", allObjects: allIngredients)
        let moduleRelationship = Relationship(key: "module", allObjects: allModules)
        let _: [ModuleIngredient] = try fetchAndImportAllRelationshipObjects(
            from: importJSON,
            arrayKey: "modules",
            relationshipKey: "ingredients",
            attributes: ["quantity"],
            parentRelationship: moduleRelationship,
            childRelationship: ingredientRelationship,
            context: context)
        
        // Import Module Attributes
        
        let attributeRelationship = Relationship(key: "attribute", allObjects: allAttributes)
        let _: [ModuleAttribute] = try fetchAndImportAllRelationshipObjects(
            from: importJSON,
            arrayKey: "modules",
            relationshipKey: "attributes",
            attributes: [],
            parentRelationship: moduleRelationship,
            childRelationship: attributeRelationship,
            context: context)
        
        // Import Module Modules
        
        let parentModuleRelationship = Relationship(key: "parent", allObjects: allModules)
        let childModuleRelationship = Relationship(key: "child", allObjects: allModules)
        let _: [ModuleModule] = try fetchAndImportAllRelationshipObjects(
            from: importJSON,
            arrayKey: "modules",
            relationshipKey: "modules",
            attributes: [],
            parentRelationship: parentModuleRelationship,
            childRelationship: childModuleRelationship,
            context: context)
        
        // Import Races
        
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
    }
    
    static private func fetchAndImportAllObjects<ObjectType: NSManagedObject>(
        from json: JSON,
        arrayKey: String,
        attributes: [String],
        toOneRelationships: [RelationshipProtocol] = [],
        toManyRelationships: [RelationshipProtocol] = [],
        idIsUUID: Bool = true,
        context: NSManagedObjectContext) throws -> [ObjectType] {
        
        let fetchRequest = ObjectType.fetchRequest() as! NSFetchRequest<ObjectType>
        var allObjects = try context.fetch(fetchRequest)
        
        if let objects = json[arrayKey].array {
            for objectJSON in objects {
                guard let object = getOrCreateObject(json: objectJSON, from: allObjects, idIsUUID: idIsUUID, context: context) else { continue }
                
                importAttributes(with: attributes, for: object, from: objectJSON)
                
                for relationship in toOneRelationships {
                    relationship.addRelationship(to: object, json: objectJSON)
                }
                
                for relationship in toManyRelationships {
                    relationship.addRelationships(to: object, json: objectJSON)
                }
                
                allObjects.append(object)
            }
        }
        
        return allObjects
    }
    
    static private func fetchAndImportAllRelationshipObjects<ObjectType: NSManagedObject>(
        from json: JSON,
        arrayKey: String,                                   // "modules"
        relationshipKey: String,                            // "ingredients"
        attributes: [String],                               // "quantity"
        parentRelationship: RelationshipProtocol,           // "module", [Module]
        childRelationship: RelationshipProtocol,            // "ingredient", [Ingredient]
        context: NSManagedObjectContext) throws -> [ObjectType] {
        
        let fetchRequest = ObjectType.fetchRequest() as! NSFetchRequest<ObjectType>
        var allObjects = try context.fetch(fetchRequest)    // [ModuleIngredient]
        
        if let parentObjects = json[arrayKey].array {
            for parentObjectJSON in parentObjects {
                guard let parentObjectID = parentObjectJSON["id"].string,
                    let objects = parentObjectJSON[relationshipKey].array else { continue }
                
                for objectJSON in objects {
                    let object: ObjectType
                    if let existingObject = allObjects.first(where: { existingObject -> Bool in
                        return parentRelationship.object(existingObject, matches: parentObjectID)
                            && childRelationship.object(existingObject, matches: objectJSON)
                    }) {
                        object = existingObject
                    } else {
                        object = ObjectType(context: context)
                        parentRelationship.addRelationship(to: object, from: parentObjectID)
                        childRelationship.addRelationship(to: object, json: objectJSON)
                    }
                    
                    importAttributes(with: attributes, for: object, from: objectJSON)
                    allObjects.append(object)
                }
            }
        }
        
        return allObjects
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
                
                let objectID = relationshipObject.value(forKey: "id")
                if let uuid = objectID as? UUID {
                    return uuid.uuidString == id
                } else if let idString = objectID as? String {
                    return idString == id
                }
                
                return false
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
