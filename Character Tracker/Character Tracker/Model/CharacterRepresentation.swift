//
//  CharacterRepresentation.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import Foundation

class CharacterRepresentation: NSObject, Codable {
    var name: String
    var modified: Date
    var moduleIngredients: [ModuleRepresentation]
    
    init?(_ character: Character) {
        guard let name = character.name,
            let modules = character.modules as? Set<Module> else { return nil }
        
        self.name = name
        self.modified = character.modified ?? Date()
        
        self.moduleIngredients = modules.sortedByLevel().compactMap({ModuleRepresentation($0)})
    }
    
    class ModuleRepresentation: NSObject, Codable {
        var name: String
        var level: Int16
        var ingredients: [IngredientRepresentation]
        
        init?(_ module: Module) {
            guard let name = module.name,
                let ingredients = module.ingredients as? Set<ModuleIngredient> else { return nil }
            
            self.name = name
            self.level = module.level
            self.ingredients = ingredients.compactMap { IngredientRepresentation($0) }
        }
        
        class IngredientRepresentation: NSObject, Codable {
            var name: String
            var quantity: Int16
            
            init?(_ moduleIngredient: ModuleIngredient) {
                guard let name = moduleIngredient.ingredient?.name else { return nil }
                self.name = name
                self.quantity = moduleIngredient.quantity
            }
        }
    }
}
