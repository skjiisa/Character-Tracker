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

class JSONRepresentation<ObjectType: NSManagedObject> {
    var arrayKey: String
    var attributes: [String]
    var toOneRelationships: [RelationshipProtocol]
    var toManyRelationships: [RelationshipProtocol]
    var idIsUUID: Bool = true
    
    init(arrayKey: String, attributes: [String], toOneRelationships: [RelationshipProtocol] = [], toManyRelationships: [RelationshipProtocol] = [], idIsUUID: Bool = true) {
        self.arrayKey = arrayKey
        self.attributes = attributes
        self.toOneRelationships = toOneRelationships
        self.toManyRelationships = toManyRelationships
        self.idIsUUID = idIsUUID
    }
    
    var allObjects: [ObjectType]?
    
    func clearObjects() {
        allObjects = nil
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
        games = JSONRepresentation<Game>(
            arrayKey: "games",
            attributes: ["name", "index", "mainline"])
        
        attributeTypes = JSONRepresentation<AttributeType>(
            arrayKey: "attribute_types",
            attributes: ["name"])
        
        attributeTypesRelationship = Relationship(key: "type", jsonRepresentation: attributeTypes)
        attributeTypeSections = JSONRepresentation<AttributeTypeSection>(
            arrayKey: "attribute_type_sections",
            attributes: ["name", "maxPriority", "minPriority"],
            toOneRelationships: [attributeTypesRelationship])
        
        gamesRelationship = Relationship(key: "games", jsonRepresentation: games)
        attributes = JSONRepresentation<Attribute>(
            arrayKey: "attributes",
            attributes: ["name"],
            toOneRelationships: [attributeTypesRelationship],
            toManyRelationships: [gamesRelationship])
        
        moduleTypes = JSONRepresentation<ModuleType>(
            arrayKey: "module_types",
            attributes: ["name"])
        
        ingredients = JSONRepresentation<Ingredient>(
            arrayKey: "ingredients",
            attributes: ["name"],
            toManyRelationships: [gamesRelationship],
            idIsUUID: false)
        
        moduleTypesRelationship = Relationship(key: "type", jsonRepresentation: moduleTypes)
        modules = JSONRepresentation<Module>(
            arrayKey: "modules",
            attributes: ["name", "level", "notes"],
            toOneRelationships: [moduleTypesRelationship],
            toManyRelationships: [gamesRelationship])
        
        races = JSONRepresentation<Race>(
            arrayKey: "races",
            attributes: ["name"],
            toManyRelationships: [gamesRelationship])
        
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
        // Import Games
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: games, context: context)
        
        // Import Attribute Types
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: attributeTypes, context: context)
        
        // Import Attribute Type Sections
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: attributeTypeSections, context: context)
        
        // Import Attributes
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: attributes, context: context)
        
        // Import Module Types
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: moduleTypes, context: context)
        
        // Import Ingredients
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: ingredients, context: context)
        
        // Import Modules
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: modules, context: context)
        
        // Import Module Ingredients
        
        let ingredientRelationship = Relationship(key: "ingredient", jsonRepresentation: ingredients)
        let moduleRelationship = Relationship(key: "module", jsonRepresentation: modules)
        let _: [ModuleIngredient] = try JSONController.fetchAndImportAllRelationshipObjects(
            from: importJSON,
            arrayKey: "modules",
            relationshipKey: "ingredients",
            attributes: ["quantity"],
            parentRelationship: moduleRelationship,
            childRelationship: ingredientRelationship,
            context: context)
        
        // Import Module Attributes
        
        let attributeRelationship = Relationship(key: "attribute", jsonRepresentation: attributes)
        let _: [ModuleAttribute] = try JSONController.fetchAndImportAllRelationshipObjects(
            from: importJSON,
            arrayKey: "modules",
            relationshipKey: "attributes",
            attributes: [],
            parentRelationship: moduleRelationship,
            childRelationship: attributeRelationship,
            context: context)
        
        // Import Module Modules
        
        let parentModuleRelationship = Relationship(key: "parent", jsonRepresentation: modules)
        let childModuleRelationship = Relationship(key: "child", jsonRepresentation: modules)
        let _: [ModuleModule] = try JSONController.fetchAndImportAllRelationshipObjects(
            from: importJSON,
            arrayKey: "modules",
            relationshipKey: "modules",
            attributes: [],
            parentRelationship: parentModuleRelationship,
            childRelationship: childModuleRelationship,
            context: context)
        
        // Import Races
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: races, context: context)
        
        // Import Characters
        
        try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: characters, context: context)
        
        CoreDataStack.shared.save(context: context)
    }
    
}
