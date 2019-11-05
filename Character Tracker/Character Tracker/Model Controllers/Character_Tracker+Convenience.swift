//
//  Character_Tracker+Convenience.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

extension Race {
    @discardableResult convenience init(name: String, vanilla: Bool, game: Game, id: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.id = id
        self.vanilla = vanilla
        self.game = game
    }
}

extension Attribute {
    @discardableResult convenience init(name: String, vanilla: Bool, game: Game, type: AttributeType, id: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.id = id
        self.vanilla = vanilla
        self.game = game
        self.type = type
    }
}

extension Character {
    @discardableResult convenience init(name: String, race: Race, game: Game, id: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.race = race
        self.game = game
        self.id = id
    }
}
