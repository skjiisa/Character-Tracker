//
//  attributeController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class AttributeController {
    
    private(set) var tempAttributes: [(attribute: Attribute, priority: Int16)] = []
    
    //MARK: Attribute CRUD
    
    func create(attribute name: String, game: Game, type: AttributeType, mod: Mod? = nil, context: NSManagedObjectContext) {
        Attribute(name: name, game: game, type: type, mod: mod, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
    func edit(attribute: Attribute, name: String, context: NSManagedObjectContext) {
        attribute.name = name
        CoreDataStack.shared.save(context: context)
    }
    
    func delete(attribute: Attribute, context: NSManagedObjectContext) {
        // Remove CharacterAttributes
        let characterFetchRequest: NSFetchRequest<CharacterAttribute> = CharacterAttribute.fetchRequest()
        characterFetchRequest.predicate = NSPredicate(format: "attribute == %@", attribute)
        
        do {
            let characterAttributes = try context.fetch(characterFetchRequest)
            
            for characterAttribute in characterAttributes {
                context.delete(characterAttribute)
            }
        } catch {
            if let name = attribute.name {
                NSLog("Could not fetch \(name)'s character attributes for removal: \(error)")
            } else {
                NSLog("Could not fetch module's character attributes for removal: \(error)")
            }
            return
        }
        
        tempAttributes.removeAll(where: { $0.attribute == attribute })
        
        context.delete(attribute)
        CoreDataStack.shared.save(context: context)
    }
    
    func add(game: Game, to attribute: Attribute, context: NSManagedObjectContext) {
        attribute.mutableSetValue(forKey: "game").add(game)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(game: Game, from attribute: Attribute, context: NSManagedObjectContext) {
        // Remove CharacterModules
        let characterFetchRequest: NSFetchRequest<CharacterAttribute> = CharacterAttribute.fetchRequest()
        characterFetchRequest.predicate = NSPredicate(format: "attribute == %@ AND character.game == %@", attribute, game)
        
        do {
            let characterAttributes = try context.fetch(characterFetchRequest)
            
            for characterAttribute in characterAttributes {
                context.delete(characterAttribute)
            }
        } catch {
            if let name = attribute.name {
                NSLog("Could not fetch \(name)'s character attributes for removal: \(error)")
            } else {
                NSLog("Could not fetch module's character attributes for removal: \(error)")
            }
            return
        }
        
        tempAttributes.removeAll(where: { $0.attribute == attribute })
        
        attribute.mutableSetValue(forKey: "game").remove(game)
        CoreDataStack.shared.save(context: context)
    }
    
    //MARK: Temp Attributes
    
    func sortTempAttributes() {
        tempAttributes.sort { attribute0, attribute1 -> Bool in
            if attribute0.priority == attribute1.priority {
                return attribute0.attribute.name ?? "" < attribute1.attribute.name ?? ""
            }
            
            return attribute0.priority < attribute1.priority
        }
    }
    
    func add(tempAttribute attribute: Attribute, priority: Int16) {
        if !tempAttributes.contains(where: { $0.attribute == attribute }) {
            tempAttributes.append((attribute, priority))
        }
        sortTempAttributes()
    }
    
    func toggle(tempAttribute attribute: Attribute, priority: Int16) {
        if tempAttributes.contains(where: { $0.attribute == attribute }) {
            remove(tempAttribute: attribute)
        } else {
            add(tempAttribute: attribute, priority: priority)
        }
        sortTempAttributes()
    }
    
    func remove(tempAttribute attribute: Attribute) {
        tempAttributes.removeAll(where: { $0.attribute == attribute })
    }
    
    func getTempAttributes(ofType type: AttributeType) -> [Attribute] {
        let attributes = tempAttributes.compactMap({ $0.attribute })
        let result = attributes.filter({ $0.type == type })
        
        return result
    }
    
    func getTempAttributes(ofType type: AttributeType, priority: Int16) -> [Attribute] {
        let tempAttributes = self.tempAttributes.filter({ $0.attribute.type == type && $0.priority == priority })
        let result = tempAttributes.compactMap({ $0.attribute })
        
        return result
    }
    
    func getTempAttributes(from section: Section) -> [Attribute]? {
        if let typeSection = section as? AttributeTypeSection,
            let type = typeSection.type {
            let priority = typeSection.minPriority
            return getTempAttributes(ofType: type, priority: priority)
        } else {
            return nil
        }
    }
    
    //MARK: Character Attributes CRUD
    
    func saveTempAttributes(to character: Character, context: NSManagedObjectContext) {
        let currentCharacterAttributes = fetchCharacterAttributes(for: character, context: context)
        
        for tempAttribute in tempAttributes {
            if let characterAttribute = currentCharacterAttributes.first(where: { $0.attribute == tempAttribute.attribute } ) {
                characterAttribute.priority = tempAttribute.priority
            } else {
                CharacterAttribute(character: character, attribute: tempAttribute.attribute, priority: tempAttribute.priority, context: context)
            }
        }
        
        tempAttributes = []
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempAttributes(for character: Character, context: NSManagedObjectContext) {
        let characterAttributes = fetchCharacterAttributes(for: character, context: context)
        
        for characterAttribute in characterAttributes {
            guard let attribute = characterAttribute.attribute else { continue }
            tempAttributes.append((attribute, characterAttribute.priority))
        }
    }
    
    func fetchCharacterAttributes(for character: Character, context: NSManagedObjectContext) -> [CharacterAttribute] {
        let fetchRequest: NSFetchRequest<CharacterAttribute> = CharacterAttribute.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "character = %@", character)
        
        do {
            let characterAttributes = try context.fetch(fetchRequest)
            
            return characterAttributes
        } catch {
            if let name = character.name {
                NSLog("Could not fetch \(name)'s attributes: \(error)")
            } else {
                NSLog("Could not fetch character's attributes: \(error)")
            }
            
            return []
        }
    }
    
    func removeMissingTempAttributes(from character: Character, context: NSManagedObjectContext) {
        let attributes: [Attribute] = tempAttributes.map({ $0.attribute })
        
        let fetchRequest: NSFetchRequest<CharacterAttribute> = CharacterAttribute.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "character == %@ AND NOT (attribute IN %@)", character, attributes)
        
        do {
            let characterAttributes = try context.fetch(fetchRequest)
            for characterAttribute in characterAttributes {
                context.delete(characterAttribute)
            }
            
            CoreDataStack.shared.save(context: context)
        } catch {
            if let name = character.name {
                NSLog("Could not fetch \(name)'s attributes for removal: \(error)")
            } else {
                NSLog("Could not fetch character's attributes for removal: \(error)")
            }
        }
    }
    
}
