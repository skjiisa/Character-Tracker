//
//  IngredientController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/15/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class IngredientController {
    
    private(set) var tempIngredients: [(ingredient: Ingredient, quantity: Int16, completed: Bool)] = []
    
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
    
    //MARK: ModuleIngredient CRUD
    
    func add(tempIngredient ingredient: Ingredient, quantity: Int16 = 0, completed: Bool = false) {
        if !tempIngredients.contains(where: { $0.ingredient == ingredient }) {
            tempIngredients.append((ingredient: ingredient, quantity: quantity, completed: completed))
        }
    }
    
    func set(quantity: Int16, for ingredient: Ingredient) {
        if let index = tempIngredients.firstIndex(where: { $0.ingredient == ingredient }) {
            tempIngredients[index].quantity = quantity
        } else {
            add(tempIngredient: ingredient, quantity: quantity)
        }
    }
    
    func toggle(tempIngredient ingredient: Ingredient) {
        if let index = tempIngredients.firstIndex(where: { $0.ingredient == ingredient }) {
            tempIngredients[index].completed.toggle()
        } else {
            add(tempIngredient: ingredient, completed: true)
        }
    }
    
    func remove(tempIngredient ingredient: Ingredient) {
        tempIngredients.removeAll(where: { $0.ingredient == ingredient })
    }
    
}
