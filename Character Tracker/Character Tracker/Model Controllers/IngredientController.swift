//
//  IngredientController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/15/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class IngredientController: EntityController {
    
    var tempEntities: [(entity: Ingredient, value: Int16)] = []
    
    //MARK: Ingredient CRUD
    
    func create(ingredient name: String, game: Game, id: String? = nil, context: NSManagedObjectContext) {
        if let id = id {
            Ingredient(name: name, game: game, id: id, context: context)
        } else {
            Ingredient(name: name, game: game, context: context)
        }
        CoreDataStack.shared.save(context: context)
    }
    
    func deleteWithoutSaving(_ ingredient: Ingredient, context: NSManagedObjectContext) {
        tempEntities.removeAll(where: { $0.entity == ingredient })
        
        ingredient.deleteRelationshipObjects(forKey: "modules", context: context)
        
        context.delete(ingredient)
    }
    
    //MARK: Temp Ingredients
    
    func set(quantity: Int16, for ingredient: Ingredient) {
        if let index = tempEntities.firstIndex(where: { $0.entity == ingredient }) {
            tempEntities[index].value = quantity
        } else {
            add(tempEntity: ingredient, value: quantity)
        }
        sortTempEntities()
    }
    
    func sortTempEntities() {
        tempEntities.sort { $0.value < $1.value }
    }
    
    //MARK: Module Ingredients CRUD
    
    func saveTempIngredients(to module: Module, context: NSManagedObjectContext) {
        guard let currentModuleIngredients = module.ingredients as? Set<ModuleIngredient> else { return }
        
        for tempIngredient in tempEntities {
            if let moduleIngredient = currentModuleIngredients.first(where: { $0.ingredient == tempIngredient.entity }) {
                // If the module already has the ingredient, make sure the quantity and completed state are up-to-date
                moduleIngredient.quantity = tempIngredient.value
            } else {
                // Add the Module Ingredient
                ModuleIngredient(module: module, ingredient: tempIngredient.entity, quantity: tempIngredient.value, context: context)
            }
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempIngredients(for module: Module, in game: Game) {
        tempEntities = []
        
        guard let moduleIngredients = module.ingredients as? Set<ModuleIngredient> else { return }
        for moduleIngredient in moduleIngredients {
            guard let ingredient = moduleIngredient.ingredient,
                let games = ingredient.games,
                games.contains(game) else { continue }
            let quantity = moduleIngredient.quantity
            tempEntities.append((ingredient, quantity))
        }
        sortTempEntities()
    }
    
    func removeMissingTempIngredients(from module: Module, context: NSManagedObjectContext) {
        let ingredients: [Ingredient] = tempEntities.map({ $0.entity })
        
        guard let existingModuleIngredients = module.ingredients as? Set<ModuleIngredient> else { return }
        let moduleIngredientsToDelete = existingModuleIngredients.filter { moduleIngredient -> Bool in
            guard let ingredient = moduleIngredient.ingredient else { return true }
            return !ingredients.contains(ingredient)
        }
        
        for moduleIngredient in moduleIngredientsToDelete {
            context.delete(moduleIngredient)
        }
    }
    
    //MARK: Mods
    
    /// Removes all Ingredients from a Mod in preparation for the Mod being deleted.
    ///
    /// If this is the only Mod to have added an Ingredient, that Ingredient will be deleted.
    /// If another Mod also added the Ingredient, it will only be removed from this Mod.
    /// - Note: Does not save the context. 
    /// - Parameters:
    ///   - mod: The Mod to remove Ingredients from.
    ///   - context: The context to delete them from.
    func removeOrDeleteAllIngredients(from mod: Mod, context: NSManagedObjectContext) {
        guard let ingredients = mod.ingredients as? Set<Ingredient> else { return }
        for ingredient in ingredients {
            // If other mods have added this ingredient, just remove it from this mod.
            // Otherwise, delete it.
            if ingredient.mods?.count ?? 0 > 1 {
                let mods = ingredient.mutableSetValue(forKey: "mods")
                mods.remove(mod)
            } else {
                deleteWithoutSaving(ingredient, context: context)
            }
        }
    }
    
}
