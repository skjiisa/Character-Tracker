//
//  attributeController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

enum AttributeTypeKeys: String, CaseIterable {
    case skill
    case objective
    case combatStyle = "combat style"
    case armorType = "armor type"
}

class AttributeController {
    
    var tempAttributes: [Attribute: Int16] = [:]
    
    func create(attribute name: String, vanilla: Bool, game: Game, type: AttributeType, context: NSManagedObjectContext) {
        Attribute(name: name, vanilla: vanilla, game: game, type: type, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
    func edit(attribute: Attribute, name: String, context: NSManagedObjectContext) {
        attribute.name = name
        CoreDataStack.shared.save(context: context)
    }
    
    func type(_ type: AttributeTypeKeys) -> AttributeType? {
        do {
            let fetchRequest: NSFetchRequest<AttributeType> = AttributeType.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", type.rawValue)
            
            let types = try CoreDataStack.shared.mainContext.fetch(fetchRequest)
            
            if types.count > 0 {
                return types[0]
            } else {
                return nil
            }
        } catch {
            NSLog("Could not fetch attribute type: \(error)")
            return nil
        }
    }
    
    func add(tempAttribute attribute: Attribute, priority: Int16) {
        tempAttributes[attribute] = priority
    }
    
    func remove(tempAttribute attribute: Attribute) {
        tempAttributes.removeValue(forKey: attribute)
    }
    
    func getTempAttributes(ofType typeKey: AttributeTypeKeys) -> [Attribute] {
        let type = self.type(typeKey)
        
        return tempAttributes.keys.filter { $0.type == type }
    }
    
    func getTempAttributes(ofType typeKey: AttributeTypeKeys, priority: Int16) -> [Attribute] {
        let type = self.type(typeKey)
        
        let attributesDictionary = tempAttributes.filter { $0.key.type == type && $0.value == priority }
        
        return attributesDictionary.map { $0.key }
    }
    
    func saveTempAttributes(to character: Character, context: NSManagedObjectContext) {
        for attributePair in tempAttributes {
            CharacterAttribute(character: character, attribute: attributePair.key, priority: attributePair.value, context: context)
        }
        
        tempAttributes = [:]
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchAttributes(for character: Character, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<CharacterAttribute> = CharacterAttribute.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "character = %@", character)
        
        do {
            let characterAttributes = try context.fetch(fetchRequest)
            for characterAttribute in characterAttributes {
                guard let attribute = characterAttribute.attribute else { continue }
                tempAttributes[attribute] = characterAttribute.priority
            }
        } catch {
            if let name = character.name {
                NSLog("Could not fetch \(name)'s attributes: \(error)")
            } else {
                NSLog("Could not fetch character's attributes: \(error)")
            }
        }
    }
    
}
