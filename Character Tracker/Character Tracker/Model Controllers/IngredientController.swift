//
//  IngredientController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/15/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class IngredientController {
    
    private(set) var tempIngredients: [(ingredient: Ingredient, quantity: Int16)] = []
    
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
        context.delete(ingredient)
        CoreDataStack.shared.save(context: context)
    }
    
    //MARK: Temp Ingredients
    
    func add(tempIngredient ingredient: Ingredient, quantity: Int16 = 0) {
        if !tempIngredients.contains(where: { $0.ingredient == ingredient }) {
            tempIngredients.append((ingredient: ingredient, quantity: quantity))
        }
    }
    
    func set(quantity: Int16, for ingredient: Ingredient) {
        if let index = tempIngredients.firstIndex(where: { $0.ingredient == ingredient }) {
            tempIngredients[index].quantity = quantity
        } else {
            add(tempIngredient: ingredient, quantity: quantity)
        }
    }
    
//    func toggle(tempIngredient ingredient: Ingredient) {
//        if let index = tempIngredients.firstIndex(where: { $0.ingredient == ingredient }) {
//            tempIngredients[index].completed.toggle()
//        } else {
//            add(tempIngredient: ingredient, completed: true)
//        }
//    }
    
    func remove(tempIngredient ingredient: Ingredient) {
        tempIngredients.removeAll(where: { $0.ingredient == ingredient })
    }
    
    //MARK: Module Ingredients CRUD
    
    func saveTempIngredients(to module: Module, context: NSManagedObjectContext) {
        let currentModuleIngredients = fetchModuleIngredients(for: module, context: context)
        
        for tempIngredient in tempIngredients {
            if let moduleIngredient = currentModuleIngredients.first(where: { $0.ingredient == tempIngredient.ingredient }) {
                // If the module already has the ingredient, make sure the quantity and completed state are up-to-date
                moduleIngredient.quantity = tempIngredient.quantity
            } else {
                // Add the Module Ingredient
                ModuleIngredient(module: module, ingredient: tempIngredient.ingredient, quantity: tempIngredient.quantity, context: context)
            }
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    func fetchTempIngredients(for module: Module, context: NSManagedObjectContext) {
        tempIngredients = []
        
        let moduleIngredients = fetchModuleIngredients(for: module, context: context)
        for moduleIngredient in moduleIngredients {
            guard let ingredient = moduleIngredient.ingredient else { continue }
            let quantity = moduleIngredient.quantity
            tempIngredients.append((ingredient, quantity))
        }
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
        let ingredients: [Ingredient] = tempIngredients.map({ $0.ingredient })
        
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
