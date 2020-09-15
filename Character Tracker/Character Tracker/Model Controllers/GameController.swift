//
//  GameController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/15/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData

class GameController: ObservableObject {
    
    /// A list of `Game`s that should show up as being checked.
    ///
    /// Used to stage changes to an object that has a reference to a set of `Game`s.
    /// If a parent view has a fetch request for `Game`s, changing this set won't cause
    /// the view to pop until the changes are saved to Core Data.
    @Published private(set) var checkedGames = Set<Game>()
    @Published private(set) var mod: Mod?
    
    /// Load the `Game`s of a `Mod` into `checkedGames`
    /// and stores a reference to the `Mod` to save to later with `saveCheckedModules(context:)`.
    /// - Parameter mod: The `Mod` to load the `Game`s of.
    func loadGames(for mod: Mod) {
        guard self.mod != mod else { return }
        self.mod = mod
        guard let games = mod.games as? Set<Game> else { return checkedGames.removeAll() }
        checkedGames = games
    }
    
    /// Add or remove a `Game` from `checkedGames`.
    ///
    /// If `checkedGames` already contains the given `Game`,
    /// remove it. Otherwise, add it.
    /// - Parameter game: The `Game` to add or remove
    func toggle(game: Game) {
        if checkedGames.contains(game) {
            checkedGames.remove(game)
        } else {
            checkedGames.insert(game)
        }
    }
    
    /// Saves the `Game`s in `checkedGames` to a `Mod`.
    /// - Parameters:
    ///   - mod: The `Mod` to save `Game`s to
    ///   - context: The Core Data context to save to
    func saveCheckedModules(to mod: Mod, context: NSManagedObjectContext) {
        let mutableGames = mod.mutableSetValue(forKey: "games")
        // Remove Games that aren't in the list
        for game in mutableGames as? Set<Game> ?? [] {
            guard !checkedGames.contains(game) else { continue }
            mutableGames.remove(game)
        }
        
        // Add new Games
        for game in checkedGames {
            mutableGames.add(game)
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
    /// Saves the `Game`s in `checkedGames` to the last loaded object
    ///
    /// Saves the `Game` list to the last object loaded from `loadGames`.
    /// - Parameter context: The Core Data context to save to
    func saveCheckedModules(context: NSManagedObjectContext) {
        if let mod = self.mod {
            saveCheckedModules(to: mod, context: context)
        }
    }
}
