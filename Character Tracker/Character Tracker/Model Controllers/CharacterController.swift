//
//  CharacterController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/4/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class CharacterController {
    
    @discardableResult func create(character name: String, race: Race, female: Bool, game: Game, context: NSManagedObjectContext) -> Character {
        let character = Character(name: name, race: race, female: female, game: game, context: context)
        CoreDataStack.shared.save(context: context)
        return character
    }
    
    func edit(character: Character, name: String, race: Race, female: Bool, context: NSManagedObjectContext) {
        character.name = name
        character.race = race
        character.female = female
        character.modified = Date()
        CoreDataStack.shared.save(context: context)
    }
    
    func delete(character: Character, context: NSManagedObjectContext) throws {
        character.deleteRelationshipObjects(forKeys: ["attributes", "modules"], context: context)
        context.delete(character)
        CoreDataStack.shared.save(context: context)
    }
    
}
