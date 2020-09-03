//
//  RacesView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/2/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct RacesView: View {
    var fetchRequest: FetchRequest<Race>
    var races: FetchedResults<Race> {
        fetchRequest.wrappedValue
    }
    
    @EnvironmentObject var gameReference: GameReference
    
    var didSelect: (Race) -> Void
    
    init(game: Game?, didSelect: @escaping (Race) -> Void = {_ in}) {
        var predicate: NSPredicate?
        if let game = game {
            predicate = NSPredicate(format: "%@ in games", game)
        }
        fetchRequest = FetchRequest(entity: Race.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: false)], predicate: predicate)
        
        self.didSelect = didSelect
    }
    
    var body: some View {
        List {
            ForEach(races, id: \.self) { race in
                Button(race.name ?? "Unknown race") {
                    self.didSelect(race)
                }
            }
        }
    }
}

struct RacesView_Previews: PreviewProvider {
    static var previews: some View {
        RacesView(game: GameReference().game)
    }
}
