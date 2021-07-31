//
//  Character_Tracker+Convenience.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

extension Race {
    @discardableResult convenience init(name: String, game: Game, mod: Mod?, id: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.id = id
        self.games = [game]
        self.mod = mod
    }
}

extension Attribute {
    @discardableResult convenience init(name: String, game: Game, type: AttributeType, id: UUID = UUID(), mod: Mod?, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.id = id
        self.games = [game]
        self.type = type
        self.mod = mod
    }
}

extension Character {
    @discardableResult convenience init(name: String, race: Race, female: Bool, game: Game, id: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.race = race
        self.female = female
        self.game = game
        self.id = id
        self.modified = Date()
    }
}

extension CharacterAttribute {
    @discardableResult convenience init(character: Character, attribute: Attribute, priority: Int16, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.character = character
        self.attribute = attribute
        self.priority = priority
    }
}

extension Module {
    @discardableResult convenience init(name: String, notes: String? = nil, level: Int16 = 0, game: Game, type: ModuleType, mod: Mod? = nil, id: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.notes = notes
        self.level = level
        self.games = [game]
        self.type = type
        self.mod = mod
        self.id = id
        self.modified = Date()
    }
    
    @discardableResult convenience init(name: String, notes: String? = nil, level: Int16 = 0, games: Set<Game>, type: ModuleType, mod: Mod? = nil, id: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.notes = notes
        self.level = level
        self.games = games as NSSet
        self.type = type
        self.mod = mod
        self.id = id
    }
}

extension CharacterModule {
    @discardableResult convenience init(character: Character, module: Module, completed: Bool = false, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.character = character
        self.module = module
        self.completed = completed
    }
}

extension Ingredient {
    @discardableResult convenience init(name: String, game: Game, id: String = UUID().uuidString, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.id = id
        self.games = [game]
    }
}

extension ModuleIngredient {
    @discardableResult convenience init(module: Module, ingredient: Ingredient, quantity: Int16, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.module = module
        self.ingredient = ingredient
        self.quantity = quantity
    }
}

extension ModuleModule {
    @discardableResult convenience init(parent: Module, child: Module, value: Int16 = 0, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.parent = parent
        self.child = child
        self.value = value
    }
}

extension ModuleAttribute {
    @discardableResult convenience init(module: Module, attribute: Attribute, value: Int16 = 0, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.attribute = attribute
        self.module = module
        self.value = value
    }
}

extension ExternalLink {
    @discardableResult
    convenience init(mod: Mod, context moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.mods = [mod]
    }
}
