//
//  CharactersViewContainer.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/2/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

// This exists because gameReference in TabBarController is not being observed,
// so it does not publish updates. Once that gets replaced with a SwiftUI
// TabView, this can be removed.
struct CharactersViewContainer: View {
    @EnvironmentObject var gameReference: GameReference
    
    var body: some View {
        CharactersView(game: gameReference.game)
    }
}

struct CharactersViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        CharactersViewContainer()
    }
}
