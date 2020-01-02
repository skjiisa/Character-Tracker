//
//  JSONController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 1/1/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData
import SwiftyJSON

class JSONController {
    
    func preloadData() {
        let context = CoreDataStack.shared.mainContext
        
        do {
            let preloadDataURL = Bundle.main.url(forResource: "Preload", withExtension: "json")!
            let preloadData = try Data(contentsOf: preloadDataURL)
            let swiftyImport = try JSON(data: preloadData)
            
            // Import Games
            
            let gamesFetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
            let allGames = try context.fetch(gamesFetchRequest)
            
            // Import Races
            
            let racesFetchRequest: NSFetchRequest<Race> = Race.fetchRequest()
            var allRaces = try context.fetch(racesFetchRequest)
            
            if let races = swiftyImport["races"].array {
                for raceJSON in races {
                    guard let race = getOrCreateObject(json: raceJSON, from: allRaces, context: context) else { continue }
                    
                    importAttributes(with: ["name"], for: race, from: raceJSON)
                    
                    addRelationships(to: race, json: raceJSON, with: "games", from: allGames)
                    
                    allRaces.append(race)
                }
                CoreDataStack.shared.save(context: context)
            }
            
            // Import Characters
            
            let charactersFetchRequest: NSFetchRequest<Character> = Character.fetchRequest()
            var allCharacters = try context.fetch(charactersFetchRequest)
            
            if let characters = swiftyImport["characters"].array {
                for characterJSON in characters {
                    guard let character = getOrCreateObject(json: characterJSON, from: allCharacters, context: context) else { continue }
                    
                    importAttributes(with: ["female", "name"], for: character, from: characterJSON)
                    
                    addRelationship(to: character, json: characterJSON, with: "race", from: allRaces)
                    addRelationship(to: character, json: characterJSON, with: "game", from: allGames)
                    allCharacters.append(character)
                }
                CoreDataStack.shared.save(context: context)
            }
        } catch {
            NSLog("\(error)")
        }
    }
    
    func getOrCreateObject<ObjectType: NSManagedObject>(json: JSON, from existingObjects: [ObjectType], context: NSManagedObjectContext) -> ObjectType? {
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
    
    func importAttributes<ObjectType: NSManagedObject>(with keys: [String], for object: ObjectType, from json: JSON) {
        for key in keys {
            let value = json[key].object
            if value is NSNull { continue }
            object.setValue(value, forKey: key)
        }
    }
    
    func addRelationship<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, json: JSON, with key: String, from relationshipObjects: [RelationshipType]) {
        guard let id = json[key].string,
            let relationshipObject = relationshipObjects.first(where: { relationshipObject -> Bool in
            guard let uuid = relationshipObject.value(forKey: "id") as? UUID else { return false }
            return uuid.uuidString == id
        }) else { return }
        
        object.setValue(relationshipObject, forKey: key)
    }
    
    func addRelationships<ObjectType: NSManagedObject, RelationshipType: NSManagedObject>(to object: ObjectType, json: JSON, with key: String, from relationshipObjects: [RelationshipType]) {
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
