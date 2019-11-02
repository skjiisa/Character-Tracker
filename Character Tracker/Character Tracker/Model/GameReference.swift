//
//  GameReference.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import Foundation

class GameReference {
    private(set) var game: Game?
    var callbacks: [( () -> Void )] = []
    
    func gameSet() {
        for callback in callbacks {
            callback()
        }
    }
    
    var name: String {
        return game?.name ?? ""
    }
    
    func set(game: Game) {
        self.game = game
        gameSet()
    }
}
