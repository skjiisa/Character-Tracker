//
//  GameReference.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import Foundation
import CoreData

class GameReference {
    private(set) var game: Game?
    var name: String {
        return game?.name ?? ""
    }
    var isSafeToChangeGame = true
    var callbacks: [( () -> Void )] = []
    
    let selectedGameKey = "SelectedGame"
    let userDefaults = UserDefaults.standard
    
    init() {
        do {
            let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
            
            if let gameName = userDefaults.string(forKey: selectedGameKey) {
                fetchRequest.predicate = NSPredicate(format: "name == %@", gameName)
            } else {
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "mainline", ascending: false),
                    NSSortDescriptor(key: "index", ascending: false)
                ]
            }
            
            let games = try CoreDataStack.shared.mainContext.fetch(fetchRequest)
            
            if games.count > 0 {
                game = games[0]
            } else {
                throw NSError()
            }
        } catch {
            NSLog("Could not load previously selected game: \(error)")
        }
    }
    
    func gameSet() {
        for callback in callbacks {
            callback()
        }
    }
    
    func set(game: Game) {
        self.game = game
        
        userDefaults.set(game.name, forKey: selectedGameKey)
        
        gameSet()
    }
}
