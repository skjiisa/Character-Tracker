//
//  CharacterController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/4/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class CharacterController {
    
    func create(character name: String, race: Race, game: Game, context: NSManagedObjectContext) {
        Character(name: name, race: race, game: game, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
    func edit(character: Character, name: String, race: Race, game: Game, context: NSManagedObjectContext) {
        Character(name: name, race: race, game: game, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
}
