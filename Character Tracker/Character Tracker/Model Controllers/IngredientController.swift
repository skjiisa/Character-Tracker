//
//  IngredientController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/15/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class IngredientController: EntityController {
    typealias Entity = Ingredient
    typealias Value = Int16
    
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
    
    func delete(ingredient: Ingredient, context: NSManagedObjectContext) {
        // Remove ModuleIngredients
        let modulesFetchRequest: NSFetchRequest<ModuleIngredient> = ModuleIngredient.fetchRequest()
        modulesFetchRequest.predicate = NSPredicate(format: "ingredient == %@", ingredient)
        
        do {
            let moduleIngredients = try context.fetch(modulesFetchRequest)
            
            for moduleIngredient in moduleIngredients {
                context.delete(moduleIngredient)
            }
        } catch {
            if let name = ingredient.name {
                NSLog("Could not fetch \(name)'s module ingredients for removal: \(error)")
            } else {
                NSLog("Could not fetch module's module ingredients for removal: \(error)")
            }
            return
        }
        
        tempEntities.removeAll(where: { $0.entity == ingredient })
        
        context.delete(ingredient)
        CoreDataStack.shared.save(context: context)
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
        let currentModuleIngredients = fetchModuleIngredients(for: module, context: context)
        
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
    
    func fetchTempIngredients(for module: Module, in game: Game, context: NSManagedObjectContext) {
        tempEntities = []
        
        let moduleIngredients = fetchModuleIngredients(for: module, context: context)
        for moduleIngredient in moduleIngredients {
            guard let ingredient = moduleIngredient.ingredient,
                let games = ingredient.games,
                games.contains(game) else { continue }
            let quantity = moduleIngredient.quantity
            tempEntities.append((ingredient, quantity))
        }
        sortTempEntities()
    }
    
    func fetchModuleIngredients(for module: Module, context: NSManagedObjectContext) -> [ModuleIngredient] {
        let fetchRequest: NSFetchRequest<ModuleIngredient> = ModuleIngredient.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "module == %@", module)
        
        do {
            let characterAttributes = try context.fetch(fetchRequest)
            
            return characterAttributes
        } catch {
            if let name = module.name {
                NSLog("Could not fetch \(name)'s ingredients: \(error)")
            } else {
                NSLog("Could not fetch module's ingredients: \(error)")
            }
        }
        
        return []
    }
    
    func removeMissingTempIngredients(from module: Module, context: NSManagedObjectContext) {
        let ingredients: [Ingredient] = tempEntities.map({ $0.entity })
        
        let fetchRequest: NSFetchRequest<ModuleIngredient> = ModuleIngredient.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "module == %@ AND NOT (ingredient IN %@)", module, ingredients)
        
        do {
            let moduleIngredients = try context.fetch(fetchRequest)
            for moduleIngredient in moduleIngredients {
                context.delete(moduleIngredient)
            }
        } catch {
            if let name = module.name {
                NSLog("Could not fetch \(name)'s ingredients for removal: \(error)")
            } else {
                NSLog("Could not fetch module's ingredients for removal: \(error)")
            }
        }
    }
    
}
