//
//  ModuleController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class ModuleController {
    
    private(set) var tempModules: [Module: Bool] = [:]
    
    //MARK: Module CRUD
    
    func create(module name: String, notes: String? = nil, level: Int16 = 0, game: Game, type: ModuleType, mod: Mod? = nil, context: NSManagedObjectContext) {
        Module(name: name, notes: notes, level: level, game: game, type: type, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
    func edit(module: Module, name: String, notes: String? = nil, level: Int16 = 0, type: ModuleType, context: NSManagedObjectContext) {
        module.name = name
        module.level = level
        module.type = type
        CoreDataStack.shared.save(context: context)
    }
    
    func delete(module: Module, context: NSManagedObjectContext) {
        context.delete(module)
        CoreDataStack.shared.save(context: context)
    }
    
    func add(game: Game, to module: Module, context: NSManagedObjectContext) {
        module.mutableSetValue(forKey: "games").add(game)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(game: Game, from module: Module, context: NSManagedObjectContext) {
        module.mutableSetValue(forKey: "games").remove(game)
        CoreDataStack.shared.save(context: context)
    }
    
    //MARK: Temp Modules
    
    func add(tempModule module: Module) {
        tempModules[module] = false
    }
    
    func toggle(tempModule module: Module) {
        if tempModules.contains(where: { $0.key == module }) {
            remove(tempModule: module)
        } else {
            add(tempModule: module)
        }
    }
    
    func remove(tempModule module: Module) {
        tempModules.removeValue(forKey: module)
    }
    
    func getTempModules(ofType type: ModuleType) -> [Module] {
        var modules = tempModules.keys.filter { $0.type == type }
        modules.sort { (module1, module2) -> Bool in
            if module1.level < module2.level {
                return true
            } else if module1.level > module2.level {
                return false
            } else if module1.name ?? "" < module2.name ?? "" {
                return true
            }
            
            return false
        }
        
        return modules
    }
    
    func getTempModules(from section: Section) -> [Module]? {
        if let type = section as? ModuleType {
            return getTempModules(ofType: type)
        }
        
        return nil
    }
    
    //MARK: Character Modules CRUD
    
    func saveTempModules(to character: Character, context: NSManagedObjectContext) {
        let currentCharacterModules = fetchCharacterModules(for: character, context: context)
        
        for modulePair in tempModules {
            if let characterModule = currentCharacterModules.first(where: { $0.module == modulePair.key }) {
                characterModule.completed = modulePair.value
            } else {
                CharacterModule(character: character, module: modulePair.key, completed: modulePair.value, context: context)
            }
        }
        
        tempModules = [:]
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempModules(for character: Character, context: NSManagedObjectContext) {
        let characterModules = fetchCharacterModules(for: character, context: context)
        
        for characterModule in characterModules {
            guard let module = characterModule.module else { continue }
            tempModules[module] = characterModule.completed
        }
    }
    
    func fetchCharacterModules(for character: Character, context: NSManagedObjectContext) -> [CharacterModule] {
        let fetchRequest: NSFetchRequest<CharacterModule> = CharacterModule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "character == %@", character)
        
        do {
            let characterAttributes = try context.fetch(fetchRequest)
            
            return characterAttributes
        } catch {
            if let name = character.name {
                NSLog("Could not fetch \(name)'s modules: \(error)")
            } else {
                NSLog("Could not fetch character's modules: \(error)")
            }
        }
        
        return []
    }
    
    func fetchCharacterModule(for character: Character, module: Module, context: NSManagedObjectContext) -> CharacterModule? {
        let fetchRequest: NSFetchRequest<CharacterModule> = CharacterModule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "character == %@ AND module == %@", character, module)
        
        do {
            let characterAttribute = try context.fetch(fetchRequest)
            
            return characterAttribute.first
        } catch {
            if let name = character.name {
                NSLog("Could not fetch \(name)'s modules: \(error)")
            } else {
                NSLog("Could not fetch character's modules: \(error)")
            }
        }
        
        return nil
    }
    
    func setCompleted(characterModule: CharacterModule, completed: Bool, context: NSManagedObjectContext) {
        characterModule.completed = completed
        CoreDataStack.shared.save(context: context)
        
        if let module = characterModule.module,
            tempModules.keys.contains(module) {
            tempModules[module] = completed
        }
    }
    
    func removeMissingTempModules(from character: Character, context: NSManagedObjectContext) {
        let modules: [Module] = tempModules.map({ $0.key })
        
        let fetchRequest: NSFetchRequest<CharacterModule> = CharacterModule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "character == %@ AND NOT (module IN %@)", character, modules)
        
        do {
            let characterModules = try context.fetch(fetchRequest)
            for characterModule in characterModules {
                context.delete(characterModule)
            }
        } catch {
            if let name = character.name {
                NSLog("Could not fetch \(name)'s attributes for removal: \(error)")
            } else {
                NSLog("Could not fetch character's attributes for removal: \(error)")
            }
        }
    }
    
}
