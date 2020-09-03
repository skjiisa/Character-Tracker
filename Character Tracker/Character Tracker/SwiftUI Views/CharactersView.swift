//
//  CharactersView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/2/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI
import CoreData

struct CharactersView: View {
    var fetchRequest: FetchRequest<Character>
    var characters: FetchedResults<Character> {
        fetchRequest.wrappedValue
    }
    
    @EnvironmentObject var gameReference: GameReference
    
    @State private var selectedCharacter: NSManagedObjectID?
    
    init(game: Game?) {
        var predicate: NSPredicate?
        if let game = game {
            predicate = NSPredicate(format: "game == %@", game)
        }
        fetchRequest = FetchRequest(entity: Character.entity(), sortDescriptors: [NSSortDescriptor(key: "modified", ascending: false)], predicate: predicate)
    }
    
    var body: some View {
        List(characters, id: \.self) { character in
            NavigationLink(destination: Text(character.name ?? "New Character"), tag: character.objectID, selection: self.$selectedCharacter) {
                VStack(alignment: .leading) {
                    Text(character.name ?? "New Character")
                        .fontWeight(.medium)
                    Text(character.race?.name ?? "")
                        .font(.footnote)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationBarTitle(gameReference.name)
    }
}

struct CharactersView_Previews: PreviewProvider {
    static var previews: some View {
        CharactersView(game: GameReference().game)
    }
}
