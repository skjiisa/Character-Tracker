//
//  CharacterController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/4/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class CharacterController {
    
    @discardableResult func create(character name: String, race: Race, game: Game, context: NSManagedObjectContext) -> Character {
        let character = Character(name: name, race: race, game: game, context: context)
        CoreDataStack.shared.save(context: context)
        return character
    }
    
    func edit(character: Character, name: String, race: Race, context: NSManagedObjectContext) {
        character.name = name
        character.race = race
        CoreDataStack.shared.save(context: context)
    }
    
}
