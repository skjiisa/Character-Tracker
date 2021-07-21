//
//  ModController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 5/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData

class ModController: ObservableObject {
    
    //MARK: CRUD
    
    @discardableResult func create(mod name: String? = nil, game: Game, context: NSManagedObjectContext) -> Mod {
        let mod = Mod(context: context)
        mod.id = UUID()
        mod.name = name
        mod.games = [game]
        CoreDataStack.shared.save(context: context)
        return mod
    }
    
    func update(mod: Mod, name: String, context: NSManagedObjectContext) {
        mod.name = name
        CoreDataStack.shared.save(context: context)
    }
    
    func delete(mod: Mod, context: NSManagedObjectContext) {
        context.delete(mod)
        CoreDataStack.shared.save(context: context)
    }
    
    func saveOrDeleteIfEmpty(_ mod: Mod, context: NSManagedObjectContext) {
        if mod.wrappedName.isEmpty,
            mod.attributes?.anyObject() == nil,
            mod.images?.count == 0,
            mod.ingredients?.anyObject() == nil,
            mod.links?.anyObject() == nil,
            mod.modules?.anyObject() == nil,
            mod.races?.anyObject() == nil {
            delete(mod: mod, context: context)
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    //MARK: Modules
    
    func add(_ module: Module, to mod: Mod, context: NSManagedObjectContext) {
        let modules = mod.mutableSetValue(forKey: "modules")
        modules.add(module)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(_ modules: [Module], from mod: Mod, context: NSManagedObjectContext) {
        let modModules = mod.mutableSetValue(forKey: "modules")
        modules.forEach(modModules.remove)
        CoreDataStack.shared.save(context: context)
    }
    
    //MARK: Ingredients
    
    func add(_ ingredient: Ingredient, to mod: Mod, context: NSManagedObjectContext) {
        let ingredients = mod.mutableSetValue(forKey: "ingredients")
        ingredients.add(ingredient)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(_ ingredients: [Ingredient], from mod: Mod, context: NSManagedObjectContext) {
        let modIngredients = mod.mutableSetValue(forKey: "ingredients")
        ingredients.forEach(modIngredients.remove)
        CoreDataStack.shared.save(context: context)
    }
    
}
