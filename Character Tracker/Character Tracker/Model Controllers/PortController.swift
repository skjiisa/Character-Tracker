//
//  PortController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 7/25/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData
import SwiftyJSON

//  JSON -> NSManagedObjects
//      Key of the array of objects in the JSON
//      Either create new object or get existing object to update
//      Keys of attributes
//      For relationships:
//          All objects of the relationship type (could be fetched and/or cached)
//          Keys of to-one and to-many relationships
//
//  NSManagedObject -> JSON
//      Keys of attributes
//      Keys of to-one and to-many relationships

//MARK: JSONRepresentation

class JSONEntity<ObjectType: NSManagedObject> {
    var allObjects: [ObjectType]?
    
    func clearObjects() {
        allObjects = nil
    }
}

class JSONRepresentation<ObjectType: NSManagedObject>: JSONEntity<ObjectType> {
    var arrayKey: String
    var attributes: [String]
    var toOneRelationships: [RelationshipProtocol]
    var toManyRelationships: [RelationshipProtocol]
    var relationshipObjects: [JSONRelationshipProtocol] = []
    var idIsUUID: Bool = true
    
    init(arrayKey: String, attributes: [String], toOneRelationships: [RelationshipProtocol] = [], toManyRelationships: [RelationshipProtocol] = [], idIsUUID: Bool = true) {
        self.arrayKey = arrayKey
        self.attributes = attributes
        self.toOneRelationships = toOneRelationships
        self.toManyRelationships = toManyRelationships
        self.idIsUUID = idIsUUID
    }
    
    func json(_ object: ObjectType) -> JSON {
        var json = JSON([:])
        
        if let id = object.value(forKey: "id") as? UUID {
            json["id"].string = id.uuidString
        }
        
        for attribute in attributes {
            guard let value = object.value(forKey: attribute) else { continue }
            json[attribute].object = value
        }
        
        for relationship in toOneRelationships {
            guard let relationshipJSON = relationship.json(object) else { continue }
            try? json.merge(with: relationshipJSON)
        }
        
        return json
    }
}

protocol JSONRelationshipProtocol {
    var key: String { get set }
    var attributes: [String] { get set }
    var parent: RelationshipProtocol { get set }
    var child: RelationshipProtocol { get set }
    
    func addRelationship<FunctionType: NSManagedObject>(to object: FunctionType, json: JSON, context: NSManagedObjectContext) throws
}

class JSONRelationship<ObjectType: NSManagedObject>: JSONEntity<ObjectType>, JSONRelationshipProtocol {
    var key: String
    var attributes: [String]
    var parent: RelationshipProtocol
    var child: RelationshipProtocol
    
    init(key: String, attributes: [String], parent: RelationshipProtocol, child: RelationshipProtocol) {
        self.key = key
        self.attributes = attributes
        self.parent = parent
        self.child = child
    }
    
    func addRelationship<FunctionType: NSManagedObject>(to inputObject: FunctionType, json: JSON, context: NSManagedObjectContext) throws {
        guard let objects = json[key].array else { return }
        
        var allObjects = try JSONController.allObjects(for: self, context: context)
        
        for objectJSON in objects {
            let object: ObjectType
            if let existingObject = allObjects.first(where: { existingObject -> Bool in
                return parent.object(existingObject, isRelatedTo: inputObject)
                    && child.object(existingObject, matches: objectJSON)
            }) {
                object = existingObject
            } else {
                object = ObjectType(context: context)
                parent.addRelationship(to: object, relationshipObject: inputObject, context: context)
                try child.addRelationship(to: object, json: objectJSON, context: context)
            }

            JSONController.importAttributes(with: attributes, for: object, from: objectJSON)
            allObjects.append(object)
        }
        
        self.allObjects = allObjects
    }
}

//MARK: PortController

// Import and Export
class PortController {
    
//    func rep<ObjectType: NSManagedObject>() -> JSONRepresentation<ObjectType>? {
//        if ObjectType.self == Game.self {
//            return games as? JSONRepresentation<ObjectType>
//        }
//
//        return nil
//    }
    
    static private(set) var shared: PortController = PortController()
    
    init() {
        // Games
        games = JSONRepresentation<Game>(
            arrayKey: "games",
            attributes: ["name", "index", "mainline"])
        
        // Attribute Types
        attributeTypes = JSONRepresentation<AttributeType>(
            arrayKey: "attribute_types",
            attributes: ["name"])
        
        // Attribute Type Sections
        attributeTypesRelationship = Relationship(key: "type", jsonRepresentation: attributeTypes)
        attributeTypeSections = JSONRepresentation<AttributeTypeSection>(
            arrayKey: "attribute_type_sections",
            attributes: ["name", "maxPriority", "minPriority"],
            toOneRelationships: [attributeTypesRelationship])
        
        // Attributes
        gamesRelationship = Relationship(key: "games", jsonRepresentation: games)
        attributes = JSONRepresentation<Attribute>(
            arrayKey: "attributes",
            attributes: ["name"],
            toOneRelationships: [attributeTypesRelationship],
            toManyRelationships: [gamesRelationship])
        
        // Module Types
        moduleTypes = JSONRepresentation<ModuleType>(
            arrayKey: "module_types",
            attributes: ["name"])
        
        // Ingredients
        ingredients = JSONRepresentation<Ingredient>(
            arrayKey: "ingredients",
            attributes: ["name"],
            toManyRelationships: [gamesRelationship],
            idIsUUID: false)
        
        // Modules
        moduleTypesRelationship = Relationship(key: "type", jsonRepresentation: moduleTypes)
        modules = JSONRepresentation<Module>(
            arrayKey: "modules",
            attributes: ["name", "level", "notes"],
            toOneRelationships: [moduleTypesRelationship],
            toManyRelationships: [gamesRelationship])
        
        // Module Ingredients
        ingredientRelationship = Relationship(key: "ingredient", jsonRepresentation: ingredients)
        moduleRelationship = Relationship(key: "module", jsonRepresentation: modules)
        moduleIngredients = JSONRelationship<ModuleIngredient>(key: "ingredients", attributes: ["quantity"], parent: moduleRelationship, child: ingredientRelationship)
        modules.relationshipObjects.append(moduleIngredients)
        
        // Module Attributes
        attributeRelationship = Relationship(key: "attribute", jsonRepresentation: attributes)
        moduleAttributes = JSONRelationship<ModuleAttribute>(key: "attributes", attributes: [], parent: moduleRelationship, child: attributeRelationship)
        modules.relationshipObjects.append(moduleAttributes)
        
        // Module Modules
        parentModuleRelationship = Relationship(key: "parent", jsonRepresentation: modules)
        childModuleRelationship = Relationship(key: "child", jsonRepresentation: modules)
        moduleModules = JSONRelationship<ModuleModule>(key: "modules", attributes: [], parent: parentModuleRelationship, child: childModuleRelationship)
        modules.relationshipObjects.append(moduleModules)
        
        // Import Races
        races = JSONRepresentation<Race>(
            arrayKey: "races",
            attributes: ["name"],
            toManyRelationships: [gamesRelationship])
        
        // Import Characters
        raceRelationship = Relationship(key: "race", jsonRepresentation: races)
        gameRelationship = Relationship(key: "game", jsonRepresentation: games)
        characters = JSONRepresentation<Character>(
            arrayKey: "characters",
            attributes: ["female", "name"],
            toOneRelationships: [raceRelationship, gameRelationship])
    }
    
    var games: JSONRepresentation<Game>
    
    var attributeTypes: JSONRepresentation<AttributeType>
    
    var attributeTypesRelationship: Relationship<AttributeType>
    var attributeTypeSections: JSONRepresentation<AttributeTypeSection>
    
    var gamesRelationship: Relationship<Game>
    var attributes: JSONRepresentation<Attribute>
    
    var moduleTypes: JSONRepresentation<ModuleType>
    
    var ingredients: JSONRepresentation<Ingredient>
    
    var moduleTypesRelationship: Relationship<ModuleType>
    var modules: JSONRepresentation<Module>
    
    var ingredientRelationship: Relationship<Ingredient>
    var moduleRelationship: Relationship<Module>
    var moduleIngredients: JSONRelationship<ModuleIngredient>

    var attributeRelationship: Relationship<Attribute>
    var moduleAttributes: JSONRelationship<ModuleAttribute>
    
    var parentModuleRelationship: Relationship<Module>
    var childModuleRelationship: Relationship<Module>
    var moduleModules: JSONRelationship<ModuleModule>
    
    var races: JSONRepresentation<Race>
    
    var raceRelationship: Relationship<Race>
    var gameRelationship: Relationship<Game>
    var characters: JSONRepresentation<Character>
    
    func preloadData() {
        do {
            let preloadDataURL = Bundle.main.url(forResource: "Preload", withExtension: "json")!
            let preloadData = try Data(contentsOf: preloadDataURL)
            let importJSON = try JSON(data: preloadData)
            try loadData(json: importJSON, context: CoreDataStack.shared.mainContext)
        } catch {
            NSLog("Error preloading data: \(error)")
        }
    }
    
    func loadData(json importJSON: JSON, context: NSManagedObjectContext) throws {
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: games, context: context)
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: attributeTypes, context: context)
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: attributeTypeSections, context: context)
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: attributes, context: context)
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: moduleTypes, context: context)
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: ingredients, context: context)
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: modules, context: context)
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: races, context: context)
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: characters, context: context)
        
        CoreDataStack.shared.save(context: context)
    }
    
}
