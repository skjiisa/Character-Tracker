//
//  attributeController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

//enum AttributeTypeKeys: String, CaseIterable {
//    case skill
//    case objective
//    case combatStyle = "combat style"
//    case armorType = "armor type"
//}

class AttributeController {
    
    var tempAttributes: [Attribute: Int16] = [:]
    
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
        context.delete(attribute)
        CoreDataStack.shared.save(context: context)
    }
    
    //MARK: Temp Attributes
    
    func add(tempAttribute attribute: Attribute, priority: Int16) {
        tempAttributes[attribute] = priority
    }
    
    func remove(tempAttribute attribute: Attribute) {
        tempAttributes.removeValue(forKey: attribute)
    }
    
    func getTempAttributes(ofType type: AttributeType) -> [Attribute] {
        return tempAttributes.keys.filter { $0.type == type }
    }
    
    func getTempAttributes(ofType type: AttributeType, priority: Int16) -> [Attribute] {
        let attributesDictionary = tempAttributes.filter { $0.key.type == type && $0.value == priority }
        let attributeKeys = attributesDictionary.map { $0.key }
        let sortedAttributes = attributeKeys.sorted { (attribute0, attribute1) -> Bool in
            guard let name0 = attribute0.name,
                let name1 = attribute1.name else { return false }
            
            return name0 > name1
        }
        
        return sortedAttributes
    }
    
    func getTempAttributes(from section: AttributeTypeSection) -> [Attribute]? {
        guard let type = section.type else { return nil }
        let priority = section.minPriority
        return getTempAttributes(ofType: type, priority: priority)
    }
    
    //MARK: Character Attributes CRUD
    
    func saveTempAttributes(to character: Character, context: NSManagedObjectContext) {
        let currentCharacterAttributes = fetchCharacterAttributes(for: character, context: context)
        
        for attributePair in tempAttributes {
            if let characterAttribute = currentCharacterAttributes.first(where: { $0.attribute == attributePair.key } ) {
                characterAttribute.priority = attributePair.value
            } else {
                CharacterAttribute(character: character, attribute: attributePair.key, priority: attributePair.value, context: context)
            }
        }
        
        tempAttributes = [:]
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchAttributes(for character: Character, context: NSManagedObjectContext) {
        let characterAttributes = fetchCharacterAttributes(for: character, context: context)
        
        for characterAttribute in characterAttributes {
            guard let attribute = characterAttribute.attribute else { continue }
            tempAttributes[attribute] = characterAttribute.priority
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
        let attributes: [Attribute] = tempAttributes.map({ $0.key })
        
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
