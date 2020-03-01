//
//  attributeController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class AttributeController: EntityController {
    
    var tempEntities: [(entity: Attribute, value: Int16)] = []
    
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
        tempEntities.removeAll(where: { $0.entity == attribute })
        
        attribute.deleteRelationshipObjects(forKeys: ["characters", "modules"], context: context)
        
        context.delete(attribute)
        CoreDataStack.shared.save(context: context)
    }
    
    func add(game: Game, to attribute: Attribute, context: NSManagedObjectContext) {
        attribute.mutableSetValue(forKey: "games").add(game)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(game: Game, from attribute: Attribute, context: NSManagedObjectContext) {
        tempEntities.removeAll(where: { $0.entity == attribute })
        
        let predicate = NSPredicate(format: "character.game == %@", game)
        attribute.deleteRelationshipObjects(forKey: "characters", using: predicate, context: context)
        
        attribute.mutableSetValue(forKey: "games").remove(game)
        CoreDataStack.shared.save(context: context)
    }
    
    //MARK: Temp Attributes
    
    func sortTempEntities() {
        tempEntities.sort { attribute0, attribute1 -> Bool in
            if attribute0.value == attribute1.value {
                return attribute0.entity.name ?? "" < attribute1.entity.name ?? ""
            }
            
            return attribute0.value < attribute1.value
        }
    }
    
    func toggle(tempAttribute attribute: Attribute, priority: Int16) {
        if tempEntities.contains(where: { $0.entity == attribute }) {
            remove(tempEntity: attribute)
        } else {
            add(tempEntity: attribute, value: priority)
        }
        sortTempEntities()
    }
    
    func getTempAttributes(ofType type: AttributeType) -> [Attribute] {
        let attributes = tempEntities.compactMap({ $0.entity })
        let result = attributes.filter({ $0.type == type })
        
        return result
    }
    
    func getTempAttributes(ofType type: AttributeType, priority: Int16) -> [Attribute] {
        let tempAttributes = self.tempEntities.filter({ $0.entity.type == type && $0.value == priority })
        let result = tempAttributes.compactMap({ $0.entity })
        
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
        
        for tempAttribute in tempEntities {
            if let characterAttribute = currentCharacterAttributes.first(where: { $0.attribute == tempAttribute.entity } ) {
                characterAttribute.priority = tempAttribute.value
            } else {
                CharacterAttribute(character: character, attribute: tempAttribute.entity, priority: tempAttribute.value, context: context)
            }
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempAttributes(for character: Character, context: NSManagedObjectContext) {
        let characterAttributes = fetchCharacterAttributes(for: character, context: context)
        
        for characterAttribute in characterAttributes {
            guard let attribute = characterAttribute.attribute else { continue }
            tempEntities.append((attribute, characterAttribute.priority))
        }
    }
    
    func fetchCharacterAttributes(for character: Character, context: NSManagedObjectContext) -> [CharacterAttribute] {
        let predicate = NSPredicate(format: "character == %@", character)
        return fetchRelationshipEntities(predicate: predicate, context: context)
    }
    
    func removeMissingTempAttributes(from character: Character, context: NSManagedObjectContext) {
        let attributes: [Attribute] = tempEntities.map({ $0.entity })
        
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
    
    //MARK: Module Attributes CRUD
    
    func saveTempAttributes(to module: Module, context: NSManagedObjectContext) {
        let currentModuleAttributes = fetchModuleAttributes(for: module, context: context)
        
        for tempAttribute in tempEntities {
            if let moduleAttribute = currentModuleAttributes.first(where: { $0.attribute == tempAttribute.entity } ) {
                moduleAttribute.value = tempAttribute.value
            } else {
                ModuleAttribute(module: module, attribute: tempAttribute.entity, value: tempAttribute.value, context: context)
            }
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempAttributes(for module: Module, context: NSManagedObjectContext) {
        tempEntities = []
        
        let moduleAttributes = fetchModuleAttributes(for: module, context: context)
        for moduleAttribute in moduleAttributes {
            guard let attribute = moduleAttribute.attribute else { continue }
            self.tempEntities.append((attribute, moduleAttribute.value))
        }
        
        sortTempEntities()
    }
    
    func fetchModuleAttributes(for module: Module, context: NSManagedObjectContext) -> [ModuleAttribute] {
        let predicate = NSPredicate(format: "module == %@", module)
        return fetchRelationshipEntities(predicate: predicate, context: context)
    }
    
    func removeMissingTempAttributes(from module: Module, context: NSManagedObjectContext) {
        let attributes: [Attribute] = tempEntities.map({ $0.entity })
        
        let fetchRequest: NSFetchRequest<ModuleAttribute> = ModuleAttribute.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "module == %@ AND NOT (attribute IN %@)", module, attributes)
        
        do {
            let moduleAttributes = try context.fetch(fetchRequest)
            for moduleAttribute in moduleAttributes {
                context.delete(moduleAttribute)
            }
            
            CoreDataStack.shared.save(context: context)
        } catch {
            if let name = module.name {
                NSLog("Could not fetch \(name)'s attributes for removal: \(error)")
            } else {
                NSLog("Could not fetch module's attributes for removal: \(error)")
            }
        }
    }
    
}
