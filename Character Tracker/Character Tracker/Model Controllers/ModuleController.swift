//
//  ModuleController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class ModuleController: EntityController {
    
    var tempEntities: [(entity: Module, value: Bool)] = []
    
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
        
        if let oldGames = module.games as? Set<Game> {
            for oldGameToRemove in oldGames.filter({ !games.contains($0) }) {
                remove(game: oldGameToRemove, from: module, context: context, shouldSave: false)
            }
            
            let mutableGames = module.mutableSetValue(forKey: "games")
            for game in games {
                if !mutableGames.contains(game) {
                    mutableGames.add(game)
                }
            }
        }
        
        module.modified = Date()
        CoreDataStack.shared.save(context: context)
    }
    
    func deleteWithoutSaving(_ module: Module, context: NSManagedObjectContext) {
        tempEntities.removeAll(where: { $0.entity == module })
        
        module.deleteRelationshipObjects(forKeys: ["characters",
                                                   "ingredients",
                                                   "parents",
                                                   "children",
                                                   "attributes"],
                                         context: context)
        
        context.delete(module)
    }
    
    func add(game: Game, to module: Module, context: NSManagedObjectContext) {
        module.mutableSetValue(forKey: "games").add(game)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(game: Game, from module: Module, context: NSManagedObjectContext, shouldSave: Bool = true) {
        tempEntities.removeAll(where: { $0.entity == module })
        
        let charactersPredicate = NSPredicate(format: "character.game == %@", game)
        module.deleteRelationshipObjects(forKey: "characters", using: charactersPredicate, context: context)
        
        let ingredientsPredicate = NSPredicate(format: "ANY ingredient.games == %@", game)
        module.deleteRelationshipObjects(forKey: "ingredients", using: ingredientsPredicate, context: context)
        
        module.mutableSetValue(forKey: "games").remove(game)
        
        if shouldSave {
            CoreDataStack.shared.save(context: context)
        }
    }
    
    //MARK: Temp Modules
    
    func sortTempEntities() {
        tempEntities.sort { $0.entity.level < $1.entity.level }
    }
    
    func toggle(tempModule module: Module) {
        if tempEntities.contains(where: { $0.entity == module }) {
            remove(tempEntity: module)
        } else {
            add(tempEntity: module, value: false)
        }
        sortTempEntities()
    }
    
    func getTempModules(ofType type: ModuleType) -> [Module] {
        let modules = tempEntities.compactMap({ $0.entity })
        let result = modules.filter({ $0.type == type })
        
        return result
    }
    
    func getTempModules(from section: TypeSection) -> [Module]? {
        if let type = section as? ModuleType {
            return getTempModules(ofType: type)
        }
        
        return nil
    }
    
    //MARK: ModuleIngredients
    
    func getModuleIngredient(module: Module, forRowAt indexPath: IndexPath) -> ModuleIngredient? {
        var moduleIngredients = module.mutableSetValue(forKey: "ingredients").compactMap({ $0 as? ModuleIngredient })
        moduleIngredients.sort { $0.quantity < $1.quantity }
        guard indexPath.row < moduleIngredients.count else { return nil }
        let moduleIngredient = moduleIngredients[indexPath.row]
        return moduleIngredient
    }
    
    @discardableResult func toggle(character: Character, ingredientAtIndexPath indexPath: IndexPath, inModule module: Module, context: NSManagedObjectContext) -> Bool? {
        guard let moduleIngredient = getModuleIngredient(module: module, forRowAt: indexPath) else { return nil }
        let moduleIngredientCharacters = moduleIngredient.mutableSetValue(forKey: "characters")
        
        let contained = moduleIngredientCharacters.contains(character)
        if contained {
            moduleIngredientCharacters.remove(character)
        } else {
            moduleIngredientCharacters.add(character)
        }
        
        character.modified = Date()
        CoreDataStack.shared.save(context: context)
        return !contained
    }
    
    //MARK: Character Modules CRUD
    
    func saveTempModules(to character: Character, context: NSManagedObjectContext) {
        guard let currentCharacterModules = character.modules as? Set<CharacterModule> else { return }
        
        for tempModule in tempEntities {
            if let characterModule = currentCharacterModules.first(where: { $0.module == tempModule.entity }) {
                characterModule.completed = tempModule.value
            } else {
                CharacterModule(character: character, module: tempModule.entity, completed: tempModule.value, context: context)
            }
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempModules(for character: Character) {
        tempEntities = []
        
        guard let characterModules = character.modules as? Set<CharacterModule> else { return }
        for characterModule in characterModules {
            guard let module = characterModule.module else { continue }
            tempEntities.append((module, characterModule.completed))
        }
        sortTempEntities()
    }
    
    func checkTempModules(againstCharacterFrom characterModule: CharacterModule, context: NSManagedObjectContext) {
        guard let character = characterModule.character else { return }
        checkTempModules(againstCharacter: character)
    }
    
    func checkTempModules(againstCharacter character: Character) {
        guard let characterModules = character.modules as? Set<CharacterModule> else { return }
        for characterModule in characterModules {
            guard let module = characterModule.module,
                let index = tempEntities.firstIndex(where: { $0.entity == module }) else { continue }
            tempEntities[index].value = characterModule.completed
        }
    }
    
    func setCompleted(characterModule: CharacterModule, completed: Bool, context: NSManagedObjectContext) {
        characterModule.completed = completed
        CoreDataStack.shared.save(context: context)
        
        if let module = characterModule.module,
            let index = tempEntities.firstIndex(where: { $0.entity == module }) {
            tempEntities[index].value = completed
        }
    }
    
    func removeMissingTempModules(from character: Character, context: NSManagedObjectContext) {
        let modules: [Module] = tempEntities.map({ $0.entity })
        
        guard let existingCharacterModules = character.modules as? Set<CharacterModule> else { return }
        let characterModulesToDelete = existingCharacterModules.filter { characterModule -> Bool in
            guard let module = characterModule.module else { return true }
            return !modules.contains(module)
        }
        
        for characterModule in characterModulesToDelete {
            context.delete(characterModule)
        }
    }
    
    //MARK: Module Modules CRUD
    
    func saveTempModules(to module: Module, context: NSManagedObjectContext) {
        guard let currentChildModules = module.children as? Set<ModuleModule> else { return }
        
        for tempModule in tempEntities {
            if let _ = currentChildModules.first(where: { $0.child == tempModule.entity }) {
                // update the value
            } else {
                ModuleModule(parent: module, child: tempModule.entity, context: context)
            }
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempModules(for module: Module, game: Game?) {
        tempEntities = []
        
        guard let childModules = module.children as? Set<ModuleModule> else { return }
        for childModule in childModules {
            guard let module = childModule.child else { continue }
            tempEntities.append((module, false))
        }
        sortTempEntities()
    }
    
    func removeMissingTempModules(from module: Module, context: NSManagedObjectContext) {
        let modules: [Module] = tempEntities.map({ $0.entity })
        
        guard let existingChildren = module.children as? Set<ModuleModule> else { return }
        let childrenToDelete = existingChildren.filter { moduleModule -> Bool in
            guard let child = moduleModule.child else { return true }
            return !modules.contains(child)
        }
        
        for child in childrenToDelete {
            context.delete(child)
        }
    }
    
    //MARK: Mods
    
    /// Deletes all Modules in a Mod in preparation for the Mod being deleted.
    ///
    /// This does not just remove the Modules from the Mod, but deletes them.
    /// - Note: Does not save the context.
    /// - Parameters:
    ///   - mod: The Mod to delete Modules of.
    ///   - context: The context to delete them from.
    func deleteAllModules(from mod: Mod, context: NSManagedObjectContext) {
        guard let modules = mod.modules as? Set<Module> else { return }
        for module in modules {
            deleteWithoutSaving(module, context: context)
        }
    }
    
}
