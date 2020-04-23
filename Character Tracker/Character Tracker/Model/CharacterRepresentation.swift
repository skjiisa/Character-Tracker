//
//  CharacterRepresentation.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import Foundation

class CharacterRepresentation: NSObject, Codable, Identifiable {
    var name: String
    var modified: Date
    var moduleIngredients: [ModuleRepresentation]
    
    init(name: String, modules: [ModuleRepresentation]) {
        self.name = name
        self.modified = Date()
        self.moduleIngredients = modules
    }
    
    init?(_ character: Character) {
        guard let name = character.name,
            let modules = character.modules as? Set<CharacterModule> else { return nil }
        
        self.name = name
        self.modified = character.modified ?? Date()
        
        self.moduleIngredients = modules.sortedByLevel().compactMap({ModuleRepresentation($0)})
    }
}

class ModuleRepresentation: NSObject, Codable, Identifiable {
    var name: String
    var level: Int16
    var ingredients: [IngredientRepresentation]
    
    init(name: String, level: Int16 = 0, ingredients: [IngredientRepresentation]) {
        self.name = name
        self.level = level
        self.ingredients = ingredients
    }
    
    init?(_ characterModule: CharacterModule) {
        guard let module = characterModule.module,
            let name = module.name,
            let ingredients = module.ingredients as? Set<ModuleIngredient> else { return nil }
        
        self.name = name
        self.level = module.level
        self.ingredients = ingredients.sorted(by: { $0.quantity < $1.quantity }).compactMap { IngredientRepresentation($0) }
    }
}

class IngredientRepresentation: NSObject, Codable, Identifiable {
    var name: String
    var quantity: Int16
    
    init(name: String, quantity: Int16) {
        self.name = name
        self.quantity = quantity
    }
    
    init?(_ moduleIngredient: ModuleIngredient) {
        guard let name = moduleIngredient.ingredient?.name else { return nil }
        self.name = name
        self.quantity = moduleIngredient.quantity
    }
}
