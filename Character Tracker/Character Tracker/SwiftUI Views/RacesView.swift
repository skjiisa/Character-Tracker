//
//  RacesView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/2/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct RacesView: View {
    @Environment(\.managedObjectContext) var moc
    var fetchRequest: FetchRequest<Race>
    var races: FetchedResults<Race> {
        fetchRequest.wrappedValue
    }
    
    @EnvironmentObject var gameReference: GameReference
    var raceController = RaceController()
    
    @State private var showingAddRaceSheet = false
    @State private var showingNewRaceAlert = false
    @State private var showingAllRaces = false
    @State private var delete: Race?
    
    var game: Game?
    var didSelect: (Race) -> Void
    var excluding: Bool
    
    init(game: Game?, didSelect: @escaping (Race) -> Void = {_ in}) {
        var predicate: NSPredicate?
        if let game = game {
            predicate = NSPredicate(format: "%@ in games", game)
        }
        fetchRequest = FetchRequest(entity: Race.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: predicate)
        
        self.game = game
        self.didSelect = didSelect
        self.excluding = false
    }
    
    init(excluding game: Game?, didSelect: @escaping (Race) -> Void = {_ in}) {
        var predicate: NSPredicate?
        if let races = game?.races {
            // I don't know why it has to be done this way, but just inverting the
            // predicate from the other initializer results in weird behavior.
            predicate = NSPredicate(format: "NOT SELF in %@", races)
        }
        fetchRequest = FetchRequest(entity: Race.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: predicate)
        
        self.game = game
        self.didSelect = didSelect
        self.excluding = true
    }
    
    func deleteButtons(for race: Race) -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        if !excluding,
            race.games?.count ?? 0 > 1 {
            buttons.append(
                .default(Text("Remove from \(self.gameReference.name)"), action: {
                    self.raceController.remove(game: self.game, from: race, context: self.moc)
                }))
        }
        
        buttons.append(
            .destructive(Text("Delete"), action: {
                self.raceController.delete(race: race, context: self.moc)
            }))
        
        buttons.append(.cancel())
        
        return buttons
    }
    
    var body: some View {
        List {
            ForEach(races, id: \.self) { race in
                Button(race.name ?? "Unknown race") {
                    self.didSelect(race)
                }
                .foregroundColor(.primary)
            }
            .onDelete { indexSet in
                guard let index = indexSet.first else { return }
                self.delete = self.races[index]
            }
            
            if !excluding {
                Section {
                    Button(action: {
                        self.showingAddRaceSheet = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Add Race")
                            Spacer()
                        }
                    }
                    .actionSheet(isPresented: $showingAddRaceSheet) {
                        ActionSheet(title: Text("Add Race"), buttons: [
                            .default(Text("Create new race"), action: {
                                self.showingNewRaceAlert = true
                            }),
                            .default(Text("Add race from other game"), action: {
                                self.showingAllRaces = true
                            }),
                            .cancel()
                        ])
                    }
                }
            }
        }
        .navigationBarTitle("Races")
        .sheet(isPresented: $showingAllRaces) {
            NavigationView {
                RacesView(excluding: self.game) { race in
                    self.raceController.add(game: self.game, to: race, context: self.moc)
                }
            }
            .environment(\.managedObjectContext, self.moc)
        }
        .actionSheet(item: $delete) { race in
            ActionSheet(title: excluding || race.games?.count ?? 0 == 1
                ? Text("Delete \(race.name ?? "")?")
                : Text("Remove \(race.name ?? "") from \(self.gameReference.name) or delete?"),
                        message: Text("\(race.name ?? "") is in: \(race.gamesList ?? "no games")."),
                        buttons: self.deleteButtons(for: race))
        }
    }
}

struct RacesView_Previews: PreviewProvider {
    static var previews: some View {
        RacesView(game: GameReference().game)
    }
}
