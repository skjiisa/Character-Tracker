//
//  ModuleController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class ModuleController {
    
    private(set) var tempModules: [(module: Module, completed: Bool)] = []
    
    //MARK: Module CRUD
    
    @discardableResult func create(module name: String, notes: String? = nil, level: Int16 = 0, games: [Game], type: ModuleType, mod: Mod? = nil, context: NSManagedObjectContext) -> Module {
        let module = Module(name: name, notes: notes, level: level, games: Set(games), type: type, context: context)
        CoreDataStack.shared.save(context: context)
        return module
    }
    
    func edit(module: Module, name: String, notes: String?, level: Int16 = 0, games: [Game], type: ModuleType, context: NSManagedObjectContext) {
        module.name = name
        module.notes = notes
        module.level = level
        module.type = type
        module.games = Set(games) as NSSet
        CoreDataStack.shared.save(context: context)
    }
    
    func delete(module: Module, context: NSManagedObjectContext) {
        
        tempModules.removeAll(where: { $0.module == module })
        
        module.deleteRelationshipObjects(forKeys: ["characters",
                                                   "ingredients",
                                                   "parents",
                                                   "children"],
                                         context: context)
        
        context.delete(module)
        CoreDataStack.shared.save(context: context)
    }
    
    func add(game: Game, to module: Module, context: NSManagedObjectContext) {
        module.mutableSetValue(forKey: "games").add(game)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(game: Game, from module: Module, context: NSManagedObjectContext) {
        // Remove CharacterModules
        let characterFetchRequest: NSFetchRequest<CharacterModule> = CharacterModule.fetchRequest()
        characterFetchRequest.predicate = NSPredicate(format: "module == %@ AND character.game == %@", module, game)
        
        do {
            let characterModules = try context.fetch(characterFetchRequest)
            
            for characterModule in characterModules {
                context.delete(characterModule)
            }
        } catch {
            if let name = module.name {
                NSLog("Could not fetch \(name)'s character modules for removal: \(error)")
            } else {
                NSLog("Could not fetch module's character modules for removal: \(error)")
            }
            return
        }
        
        // Remove ModuleIngredients
        let ingredientFetchRequest: NSFetchRequest<ModuleIngredient> = ModuleIngredient.fetchRequest()
        ingredientFetchRequest.predicate = NSPredicate(format: "module == %@ AND ANY ingredient.games == %@", module, game)
        
        let moduleGamesSet = module.mutableSetValue(forKey: "games")
        moduleGamesSet.remove(game)
        
        do {
            let moduleIngredients = try context.fetch(ingredientFetchRequest)
            
            for moduleIngredient in moduleIngredients {
                if let ingredientGamesSet = moduleIngredient.ingredient?.mutableSetValue(forKey: "games"),
                    ingredientGamesSet.count == 1,
                    ingredientGamesSet.contains(game){
                    context.delete(moduleIngredient)
                }
            }
        } catch {
            if let name = module.name {
                NSLog("Could not fetch \(name)'s module ingredients for removal: \(error)")
            } else {
                NSLog("Could not fetch module's module ingredients for removal: \(error)")
            }
            return
        }
        
        tempModules.removeAll(where: { $0.module == module })
        
        CoreDataStack.shared.save(context: context)
    }
    
    //MARK: Temp Modules
    
    func sortTempModules() {
        tempModules.sort { $0.module.level < $1.module.level }
    }
    
    func add(tempModule module: Module, completed: Bool = false) {
        if !tempModules.contains(where: { $0.module == module }) {
            tempModules.append((module, completed))
        }
        sortTempModules()
    }
    
    func toggle(tempModule module: Module) {
        if tempModules.contains(where: { $0.module == module }) {
            remove(tempModule: module)
        } else {
            add(tempModule: module)
        }
        sortTempModules()
    }
    
    func remove(tempModule module: Module) {
        tempModules.removeAll(where: { $0.module == module })
    }
    
    func getTempModules(ofType type: ModuleType) -> [Module] {
        let modules = tempModules.compactMap({ $0.module })
        let result = modules.filter({ $0.type == type })
        
        return result
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
        
        for tempModule in tempModules {
            if let characterModule = currentCharacterModules.first(where: { $0.module == tempModule.module }) {
                characterModule.completed = tempModule.completed
            } else {
                CharacterModule(character: character, module: tempModule.module, completed: tempModule.completed, context: context)
            }
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempModules(for character: Character, context: NSManagedObjectContext) {
        tempModules = []
        
        let characterModules = fetchCharacterModules(for: character, context: context)
        for characterModule in characterModules {
            guard let module = characterModule.module else { continue }
            tempModules.append((module, characterModule.completed))
        }
        sortTempModules()
    }
    
    func checkTempModules(againstCharacterFrom characterModule: CharacterModule, context: NSManagedObjectContext) {
        guard let character = characterModule.character else { return }
        checkTempModules(againstCharacter: character, context: context)
    }
    
    func checkTempModules(againstCharacter character: Character, context: NSManagedObjectContext) {
        let characterModules = fetchCharacterModules(for: character, context: context)
        for fetchedCharacterModule in characterModules {
            guard let module = fetchedCharacterModule.module,
                let index = tempModules.firstIndex(where: { $0.module == module }) else { continue }
            tempModules[index].completed = fetchedCharacterModule.completed
        }
    }
    
    func fetchCharacterModules(for character: Character, context: NSManagedObjectContext) -> [CharacterModule] {
        let fetchRequest: NSFetchRequest<CharacterModule> = CharacterModule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "character == %@", character)
        
        do {
            let characterModule = try context.fetch(fetchRequest)
            return characterModule
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
            let characterModule = try context.fetch(fetchRequest)
            return characterModule.first
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
            let index = tempModules.firstIndex(where: { $0.module == module }) {
            tempModules[index].completed = completed
        }
    }
    
    func removeMissingTempModules(from character: Character, context: NSManagedObjectContext) {
        let modules: [Module] = tempModules.map({ $0.module })
        
        let fetchRequest: NSFetchRequest<CharacterModule> = CharacterModule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "character == %@ AND NOT (module IN %@)", character, modules)
        
        do {
            let characterModules = try context.fetch(fetchRequest)
            for characterModule in characterModules {
                context.delete(characterModule)
            }
        } catch {
            if let name = character.name {
                NSLog("Could not fetch \(name)'s modules for removal: \(error)")
            } else {
                NSLog("Could not fetch character's modules for removal: \(error)")
            }
        }
    }
    
    //MARK: Module Modules CRUD
    
    func saveTempModules(to module: Module, context: NSManagedObjectContext) {
        let currentChildModules = fetchChildModules(for: module, context: context)
        
        for tempModule in tempModules {
            if let _ = currentChildModules.first(where: { $0.child == tempModule.module }) {
                // update the value
            } else {
                ModuleModule(parent: module, child: tempModule.module, context: context)
            }
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempModules(for module: Module, game: Game?, context: NSManagedObjectContext) {
        tempModules = []
        
        let childModules = fetchChildModules(for: module, game: game, context: context)
        for childModule in childModules {
            guard let module = childModule.child else { continue }
            tempModules.append((module, false))
        }
        sortTempModules()
    }
    
    func fetchChildModules(for module: Module, game: Game? = nil, context: NSManagedObjectContext) -> [ModuleModule] {
        let fetchRequest: NSFetchRequest<ModuleModule> = ModuleModule.fetchRequest()
        if let game = game {
            fetchRequest.predicate = NSPredicate(format: "parent == %@ AND ANY child.games == %@", module, game)
        } else {
            fetchRequest.predicate = NSPredicate(format: "parent == %@", module)
        }
        
        do {
            let moduleModules = try context.fetch(fetchRequest)
            return moduleModules
        } catch {
            if let name = module.name {
                NSLog("Could not fetch \(name)'s modules: \(error)")
            } else {
                NSLog("Could not fetch module's modules: \(error)")
            }
        }
        
        return []
    }
    
    func removeMissingTempModules(from module: Module, context: NSManagedObjectContext) {
        let modules: [Module] = tempModules.map({ $0.module })
        
        let fetchRequest: NSFetchRequest<ModuleModule> = ModuleModule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parent == %@ AND NOT (child IN %@)", module, modules)
        
        do {
            let modulesToRemove = try context.fetch(fetchRequest)
            for moduleToRemove in modulesToRemove {
                context.delete(moduleToRemove)
            }
        } catch {
            if let name = module.name {
                NSLog("Could not fetch \(name)'s modules for removal: \(error)")
            } else {
                NSLog("Could not fetch module's modules for removal: \(error)")
            }
        }
    }
    
}
