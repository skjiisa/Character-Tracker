//
//  ModsViewContainer.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/15/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ModsViewContainer: View {
    @EnvironmentObject var gameReference: GameReference
    
    var body: some View {
        ModsView(game: gameReference.game)
    }
}
