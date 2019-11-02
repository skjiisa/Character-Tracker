//
//  RaceController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class RaceController {
    
    func create(race name: String, vanilla: Bool, game: Game, context: NSManagedObjectContext) {
        Race(name: name, vanilla: vanilla, game: game, context: context)
        CoreDataStack.shared.save(context: context)
    }
    
    func edit(race: Race, name: String, context: NSManagedObjectContext) {
        race.name = name
        CoreDataStack.shared.save(context: context)
    }
    
}
