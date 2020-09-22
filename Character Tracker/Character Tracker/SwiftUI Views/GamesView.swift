//
//  GamesView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/15/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct GamesView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(entity: Game.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]) var games: FetchedResults<Game>
    
    @ObservedObject var gameController: GameController
    
    init(gameController: GameController) {
        self.gameController = gameController
    }
    
    init(mod: Mod, gameController: GameController) {
        gameController.loadGames(for: mod)
        self.init(gameController: gameController)
    }
    
    var body: some View {
        List {
            ForEach(games) { game in
                Button(action: {
                    self.gameController.toggle(game: game)
                }) {
                    HStack {
                        Text(game.name ?? "Unknown game")
                        if self.gameController.checkedGames.contains(game) {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(Font.body.bold())
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .onDisappear {
            guard !self.presentationMode.wrappedValue.isPresented else { return }
            self.gameController.saveCheckedModules(context: self.moc)
        }
    }
}

struct GamesView_Previews: PreviewProvider {
    static var previews: some View {
        GamesView(gameController: GameController())
    }
}
