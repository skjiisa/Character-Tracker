//
//  RaceController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class RaceController {
    
    func create(race name: String, game: Game, mod: Mod? = nil, context: NSManagedObjectContext) {
        Race(name: name, game: game, mod: mod, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
    func edit(race: Race, name: String, context: NSManagedObjectContext) {
        race.name = name
        CoreDataStack.shared.save(context: context)
    }
    
    func delete(race: Race, context: NSManagedObjectContext) {
        context.delete(race)
        CoreDataStack.shared.save(context: context)
    }
    
    func add(game: Game, to race: Race, context: NSManagedObjectContext) {
        race.mutableSetValue(forKey: "game").add(game)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(game: Game, from race: Race, context: NSManagedObjectContext) {
        race.mutableSetValue(forKey: "game").remove(game)
        CoreDataStack.shared.save(context: context)
    }
    
}
