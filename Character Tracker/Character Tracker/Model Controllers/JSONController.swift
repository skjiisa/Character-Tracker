//
//  JSONController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 1/1/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData
import SwiftyJSON

class JSONController {
    
    func preloadData() {
        let context = CoreDataStack.shared.mainContext
        
        do {
            let preloadDataURL = Bundle.main.url(forResource: "Preload", withExtension: "json")!
            let preloadData = try Data(contentsOf: preloadDataURL)
            let swiftyImport = try JSON(data: preloadData)
            
            // Import Games
            
            let gamesFetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
            let allGames = try context.fetch(gamesFetchRequest)
            
            // Import Races
            
            let racesFetchRequest: NSFetchRequest<Race> = Race.fetchRequest()
            var allRaces = try context.fetch(racesFetchRequest)
            
            if let races = swiftyImport["races"].array {
                for race in races {
                    guard let idString = race["id"].string,
                        let uuid = UUID(uuidString: idString),
                        let name = race["name"].string,
                        let games = race["games"].array,
                        let firstGameID = games.first?.string,
                        let firstGame = allGames.first(where: { $0.id?.uuidString == firstGameID }) else { continue }
                    print(name)
                    
                    if let existingRace = allRaces.first(where: { $0.id == uuid }) {
                        // TODO: Update race
                    } else {
                        let newRace = Race(name: name, game: firstGame, mod: nil, id: uuid, context: context)
                        allRaces.append(newRace)
                    }
                }
                CoreDataStack.shared.save(context: context)
            }
            
            // Import Characters
            
            let charactersFetchRequest: NSFetchRequest<Character> = Character.fetchRequest()
            var allCharacters = try context.fetch(charactersFetchRequest)
            
            if let characters = swiftyImport["characters"].array {
                for character in characters {
                    guard let idString = character["id"].string,
                        let uuid = UUID(uuidString: idString),
                        let name = character["name"].string,
                        let raceID = character["race"].string,
                        let race = allRaces.first(where: { $0.id?.uuidString == raceID }),
                        let gameID = character["game"].string,
                        let game = allGames.first(where: { $0.id?.uuidString == gameID }),
                        let female = character["female"].bool else { continue }
                    print(character["name"].stringValue)
                    
                    if let existingCharacter = allCharacters.first(where: { $0.id == uuid }) {
                        // TODO: Update character
                    } else {
                        let newCharacter = Character(name: name, race: race, female: female, game: game, id: uuid, context: context)
                        allCharacters.append(newCharacter)
                    }
                }
                CoreDataStack.shared.save(context: context)
            }
        } catch {
            NSLog("\(error)")
        }
    }
}
