//
//  PortController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 7/25/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON
import EFQRCode
import MobileCoreServices

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

protocol JSONRepresentationProtocol {
    func clearObjects()
}

class JSONRepresentation<ObjectType: NSManagedObject>: JSONEntity<ObjectType>, JSONRepresentationProtocol {
    var arrayKey: String
    var attributes: [String]
    var toOneRelationships: [RelationshipContainer]
    var toManyRelationships: [RelationshipContainer]
    var relationshipObjects: [JSONRelationshipProtocol] = []
    var idIsUUID: Bool = true
    
    init(arrayKey: String, attributes: [String], toOneRelationships: [RelationshipContainer] = [], toManyRelationships: [RelationshipContainer] = [], idIsUUID: Bool = true) {
        self.arrayKey = arrayKey
        self.attributes = attributes
        self.toOneRelationships = toOneRelationships
        self.toManyRelationships = toManyRelationships
        self.idIsUUID = idIsUUID
    }
    
    func json(_ object: ObjectType) -> (objectJSON: JSON, relationshipsJSON: JSON) {
        var json = JSON([:])
        var relationships = JSON()
        
        if let id = object.idString {
            json["id"].string = id
        }
        
        for attribute in attributes {
            guard let value = object.value(forKey: attribute) else { continue }
            json[attribute].object = value
        }
        
        for relationship in toOneRelationships {
            let tuple = relationship.relationship.json(object)
            if relationship.exportObjects,
                let object = tuple.objectJSON {
                try? relationships.merge(with: object)
            }
            if let relationshipJSON = tuple.relationshipJSON {
                try? json.merge(with: relationshipJSON)
            }
        }
        
        for relationship in toManyRelationships {
            let tuple = relationship.relationship.json(object)
            if relationship.exportObjects,
                let object = tuple.objectJSON {
                try? relationships.merge(with: object)
            }
            if let relationshipJSON = tuple.relationshipJSON {
                try? json.merge(with: relationshipJSON)
            }
        }
        
        for relationship in relationshipObjects {
            guard let relationshipJSON = relationship.json(object) else { continue }
            try? json.merge(with: relationshipJSON)
        }
        
        return (json, relationships)
    }
    
    func json(_ objects: [ObjectType]) -> JSON {
        var jsonObjects: [JSON] = []
        var relationships = JSON()
        
        for object in objects {
            let tuple = json(object)
            jsonObjects.append(tuple.objectJSON)
            try? relationships.merge(with: tuple.relationshipsJSON)
        }
        
        let json = JSON([arrayKey: jsonObjects])
        
        return (try? json.merged(with: relationships)) ?? json
    }
    
    override func clearObjects() {
        super.clearObjects()
        relationshipObjects.forEach { $0.clearObjects() }
    }
}

//MARK: JSONRelationship

protocol JSONRelationshipProtocol {
    var key: String { get set }
    var attributes: [String] { get set }
    var parent: RelationshipProtocol { get set }
    var child: RelationshipProtocol { get set }
    
    func addRelationship<FunctionType: NSManagedObject>(to object: FunctionType, json: JSON, context: NSManagedObjectContext) throws
    func json<ObjectType: NSManagedObject>(_ object: ObjectType) -> JSON?
    func clearObjects()
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
    
    func json<ObjectType: NSManagedObject>(_ object: ObjectType) -> JSON? {
        guard let relationshipObjects = object.value(forKey: key) as? Set<NSManagedObject> else { return nil }
        
        var objects: [JSON] = []
        
        for object in relationshipObjects {
            guard let relationshipObject = object.value(forKey: child.key) as? NSManagedObject,
                let id = relationshipObject.idString else { continue }
            
            var json = JSON([child.key:id])
            
            for attribute in attributes {
                guard let attributeValue = object.value(forKey: attribute) else { continue }
                json[attribute].object = attributeValue
            }
            
            objects.append(json)
        }
        
        if objects.count == 0 {
            return nil
        }
        
        return JSON([key: objects])
    }
}

//MARK: PortController

// Import and Export
class PortController {
    
    static private(set) var shared: PortController = PortController()
    
    var lastImport: [String] = []
    
    //MARK: Config
    
    private var jsonRepresentations: [String: JSONRepresentationProtocol] = [:]
    
    func jsonRepresentation<ObjectType: NSManagedObject>(for _: ObjectType) -> JSONRepresentation<ObjectType>? {
        jsonRepresentations[String(describing: ObjectType.self)] as? JSONRepresentation<ObjectType>
    }
    
    func jsonRepresentation<ObjectType: NSManagedObject>(for _: [ObjectType]) -> JSONRepresentation<ObjectType>? {
        jsonRepresentations[String(describing: ObjectType.self)] as? JSONRepresentation<ObjectType>
    }
    
    func jsonRepresentation<ObjectType: NSManagedObject>() -> JSONRepresentation<ObjectType>?  {
        jsonRepresentations[String(describing: ObjectType.self)] as? JSONRepresentation<ObjectType>
    }
    
    func jsonRepresentation<ObjectType: NSManagedObject>(_: ObjectType.Type) -> JSONRepresentation<ObjectType>?  {
        jsonRepresentations[String(describing: ObjectType.self)] as? JSONRepresentation<ObjectType>
    }
    
    func setRep<ObjectType: NSManagedObject>(_ rep: JSONRepresentation<ObjectType>) {
        jsonRepresentations[String(describing: ObjectType.self)] = rep
    }
    
    init() {
        // Images
        // There aren't actually going to be any Images in the top-level JSON.
        // They will be created implicitly with each entity.
        let images = JSONRepresentation<ImageLink>(arrayKey: "images", attributes: [])
        let imagesRelationship = Relationship(key: "images", orderedSet: true, createIfNotFound: true, jsonRepresentation: images)
        
        // Games
        let games = JSONRepresentation<Game>(
            arrayKey: "games",
            attributes: ["name", "index", "mainline"])
        setRep(games)
        
        // Attribute Types
        let attributeTypes = JSONRepresentation<AttributeType>(
            arrayKey: "attribute_types",
            attributes: ["name"])
        setRep(attributeTypes)
        
        // Attribute Type Sections
        let attributeTypesRelationship = Relationship(key: "type", jsonRepresentation: attributeTypes)
        let attributeTypeSections = JSONRepresentation<AttributeTypeSection>(
            arrayKey: "attribute_type_sections",
            attributes: ["name", "maxPriority", "minPriority"],
            toOneRelationships: [.init(attributeTypesRelationship, required: true)])
        setRep(attributeTypeSections)
        
        // Attributes
        let gamesRelationship = Relationship(key: "games", jsonRepresentation: games)
        let attributes = JSONRepresentation<Attribute>(
            arrayKey: "attributes",
            attributes: ["name"],
            toOneRelationships: [.init(attributeTypesRelationship, required: true)],
            toManyRelationships: [.init(gamesRelationship, required: true)])
        setRep(attributes)
        
        // Module Types
        let moduleTypes = JSONRepresentation<ModuleType>(
            arrayKey: "module_types",
            attributes: ["name"])
        setRep(moduleTypes)
        
        // Ingredients
        let ingredients = JSONRepresentation<Ingredient>(
            arrayKey: "ingredients",
            attributes: ["name"],
            toManyRelationships: [.init(gamesRelationship, required: true)],
            idIsUUID: false)
        setRep(ingredients)
        
        // Modules
        let moduleTypesRelationship = Relationship(key: "type", jsonRepresentation: moduleTypes)
        let modules = JSONRepresentation<Module>(
            arrayKey: "modules",
            attributes: ["name", "level", "notes"],
            toOneRelationships: [.init(moduleTypesRelationship, required: true)],
            toManyRelationships: [.init(gamesRelationship, required: true),
                                  .init(imagesRelationship)])
        setRep(modules)
        
        // Module Ingredients
        let ingredientRelationship = Relationship(key: "ingredient", jsonRepresentation: ingredients)
        let moduleRelationship = Relationship(key: "module", jsonRepresentation: modules)
        let moduleIngredients = JSONRelationship<ModuleIngredient>(key: "ingredients", attributes: ["quantity"], parent: moduleRelationship, child: ingredientRelationship)
        modules.relationshipObjects.append(moduleIngredients)
        
        // Module Attributes
        let attributeRelationship = Relationship(key: "attribute", jsonRepresentation: attributes)
        let moduleAttributes = JSONRelationship<ModuleAttribute>(key: "attributes", attributes: [], parent: moduleRelationship, child: attributeRelationship)
        modules.relationshipObjects.append(moduleAttributes)
        
        // Module Modules
        let parentModuleRelationship = Relationship(key: "parent", jsonRepresentation: modules)
        let childModuleRelationship = Relationship(key: "child", jsonRepresentation: modules)
        let moduleModules = JSONRelationship<ModuleModule>(key: "children", attributes: [], parent: parentModuleRelationship, child: childModuleRelationship)
        modules.relationshipObjects.append(moduleModules)
        
        // Races
        let races = JSONRepresentation<Race>(
            arrayKey: "races",
            attributes: ["name"],
            toManyRelationships: [.init(gamesRelationship, required: true)])
        setRep(races)
        
        // Characters
        let raceRelationship = Relationship(key: "race", jsonRepresentation: races)
        let gameRelationship = Relationship(key: "game", jsonRepresentation: games)
        let characters = JSONRepresentation<Character>(
            arrayKey: "characters",
            attributes: ["female", "name"],
            toOneRelationships: [.init(raceRelationship, required: true),
                                 .init(gameRelationship, required: true)])
        setRep(characters)
        
        // Character Modules
        
        let characterRelationship = Relationship(key: "character", jsonRepresentation: characters)
        let characterModules = JSONRelationship<CharacterModule>(key: "modules", attributes: [], parent: characterRelationship, child: moduleRelationship)
        characters.relationshipObjects.append(characterModules)
        
        // Mods
        let modulesRelationship = Relationship(key: "modules", jsonRepresentation: modules)
        let ingredientsRelationship = Relationship(key: "ingredients", jsonRepresentation: ingredients)
        let mods = JSONRepresentation<Mod>(
            arrayKey: "mods",
            attributes: ["name"],
            toManyRelationships: [
                .init(gamesRelationship, exportObjects: false, required: true),
                .init(modulesRelationship, exportObjects: true),
                .init(ingredientsRelationship, exportObjects: true),
                .init(imagesRelationship, exportObjects: true)
        ])
        setRep(mods)
    }
    
    //MARK: Import
    
    func preloadData() {
        lastImport.removeAll()
        
        do {
            let preloadDataURL = Bundle.main.url(forResource: "Preload", withExtension: "json")!
            let preloadData = try Data(contentsOf: preloadDataURL)
            let importJSON = try JSON(data: preloadData)
            try importData(json: importJSON, context: CoreDataStack.shared.mainContext)
            
            CoreDataStack.shared.save(context: CoreDataStack.shared.mainContext)
        } catch {
            NSLog("Error preloading data: \(error)")
        }
    }
    
    func importClass<ObjectType: NSManagedObject>(_: ObjectType.Type, json importJSON: JSON, context: NSManagedObjectContext) throws {
        if let rep = jsonRepresentation(ObjectType.self) {
            lastImport.append(contentsOf: try JSONController.fetchAndImportAllObjects(from: importJSON, jsonRepresentation: rep, context: context))
        }
    }
    
    func importData(json importJSON: JSON, context: NSManagedObjectContext) throws {
        try importClass(Game.self, json: importJSON, context: context)
        try importClass(AttributeType.self, json: importJSON, context: context)
        try importClass(AttributeTypeSection.self, json: importJSON, context: context)
        try importClass(Attribute.self, json: importJSON, context: context)
        try importClass(ModuleType.self, json: importJSON, context: context)
        try importClass(Ingredient.self, json: importJSON, context: context)
        try importClass(Module.self, json: importJSON, context: context)
        try importClass(Race.self, json: importJSON, context: context)
        try importClass(Character.self, json: importJSON, context: context)
        try importClass(Mod.self, json: importJSON, context: context)
        
        jsonRepresentations.values.forEach { $0.clearObjects() }
    }
    
    @discardableResult
    func importOnBackgroundContext(string: String, context: NSManagedObjectContext) -> [String] {
        let json = JSON(parseJSON: string)
        lastImport.removeAll()
        
        do {
            try importData(json: json, context: context)
        } catch {
            NSLog("Error importing JSON: \(error)")
        }
        
        return lastImport
    }
    
    //MARK: Export
    
    func jsonString<ObjectType: NSManagedObject>(for objects: [ObjectType], prettyPrinted: Bool = true) -> String? {
        let jsonRep = jsonRepresentation(for: objects)
        // I don't specifically want fragments allowed here,
        // but you can't have no option. It defaults to pretty printed
        return jsonRep?.json(objects).rawString(options: prettyPrinted ? .prettyPrinted : .fragmentsAllowed)
    }
    
    func exportToQRCode<ObjectType: NSManagedObject>(for object: ObjectType) -> CGImage? {
        exportToQRCode(for: [object])
    }
    
    func exportToQRCode<ObjectType: NSManagedObject>(for objects: [ObjectType]) -> CGImage? {
        guard let json = jsonString(for: objects, prettyPrinted: false),
            let icon = UIImage(named: "IconVector"),
            let inputImage = CIImage(image: icon) else { return nil }
        
        var watermark: CGImage?
        
        let context = CIContext(options: nil)
        let blur = CIFilter(name: "CIGaussianBlur")
        blur?.setValue(inputImage, forKey: kCIInputImageKey)
//        blur?.setValue(10, forKey: kCIInputRadiusKey)
        let ciImage = blur?.outputImage
        if let ciImage = ciImage {
            watermark = context.createCGImage(ciImage, from: inputImage.extent)
        }
        
        return EFQRCode.generate(content: json,
                                 size: EFIntSize(width: 512, height: 512),
                                 watermark: watermark,
                                 inputCorrectionLevel: .m,
                                 magnification: EFIntSize(width: 10, height: 10))
    }
    
    func saveTempQRCode(cgImage: CGImage) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("QRCode")
            .appendingPathExtension("png")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, nil)
        return CGImageDestinationFinalize(destination) ? url : nil
    }
    
    func saveTempQRCode<ObjectType: NSManagedObject>(for object: ObjectType) -> URL? {
        guard let qrCode = exportToQRCode(for: object) else { return nil }
        return saveTempQRCode(cgImage: qrCode)
    }
    
    func saveTempJSON<ObjectType: NSManagedObject>(for object: ObjectType) -> URL? {
        guard let json = jsonString(for: [object]) else { return nil }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("export")
            .appendingPathExtension("json")
        
        do {
            try json.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            NSLog("Error writing JSON to file: \(error)")
        }
        
        return nil
    }
    
    func exportJSONText<ObjectType: NSManagedObject>(for object: ObjectType) -> String? {
        guard let jsonString = jsonString(for: [object]) else { return nil }
        
        return UserDefaults.standard.bool(forKey: "jsonExportBackticks") ? "```json\n" + jsonString + "\n```" : jsonString
    }
    
    func clearFilesFromTempDirectory() {
        let fileManager = FileManager.default
        do {
            let tmp = fileManager.temporaryDirectory
            for file in try fileManager.contentsOfDirectory(atPath: tmp.path) {
                try fileManager.removeItem(atPath: tmp.appendingPathComponent(file).path)
            }
            print("Cleaned temp directory.")
        } catch {
            NSLog("Error clearing files from temp directory: \(error)")
        }
    }
    
}
