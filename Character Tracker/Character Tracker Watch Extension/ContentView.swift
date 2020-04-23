//
//  ContentView.swift
//  Character Tracker Watch Extension
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var characterList: CharacterList
    
    var body: some View {
        VStack {
            List {
                ForEach(characterList.characters) { character in
                    NavigationLink(destination: CharacterIngredientsView(character: character)) {
                        Text(character.name)
                    }
                }
                
                Button(action: {
                    self.characterList.refresh()
                }) {
                    Text("Refresh characters")
                }
            }
            
            if characterList.characters.count == 0 {
                Text("Loading characters...")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let previewCharacters = [
            CharacterRepresentation(name: "Ja'Zakajirr", modules: []),
            CharacterRepresentation(name: "Geetum-Za", modules: []),
            CharacterRepresentation(name: "Malula", modules: []),
            CharacterRepresentation(name: "Candella", modules: [])
        ]
        let characterList = CharacterList(characters: previewCharacters, connectivityProvider: PhoneConnectivityProvider())
        return ContentView(characterList: characterList)
    }
}
