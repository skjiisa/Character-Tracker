//
//  ModuleController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class ModuleController {
    
    private(set) var tempModules: [Module] = []
    
    //MARK: Module CRUD
    
    func create(module name: String, game: Game, type: ModuleType, mod: Mod? = nil, context: NSManagedObjectContext) {
        Module(name: name, game: game, type: type, mod: mod, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
    func edit(module: Module, name: String, type: ModuleType, context: NSManagedObjectContext) {
        module.name = name
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
        tempModules.append(module)
    }
    
    func remove(tempModule module: Module) {
        tempModules.removeAll(where: { $0 == module })
    }
    
    func getTempModules(ofType type: ModuleType) -> [Module] {
        return tempModules.filter { $0.type == type }
    }
    
    func getTempModules(from section: Section) -> [Module]? {
        if let type = section as? ModuleType {
            return getTempModules(ofType: type)
        }
        
        return nil
    }
    
}
