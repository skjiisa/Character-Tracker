//
//  ContentView.swift
//  Character Tracker Watch Extension
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: CharacterList
    
    var body: some View {
        VStack{
            List {
                ForEach(viewModel.characters, id: \.self) { character in
                    Text(character)
                }
                
                Button(action: {
                    self.viewModel.refresh()
                }) {
                    Text("Refresh characters")
                }
            }
            
            if viewModel.characters.count == 0 {
                Text("Loading characters...")
            }
        }.onAppear {
            self.viewModel.refresh()
        }
    }
}

final class CharacterList: ObservableObject {
    @Published private(set) var characters: [String]
    
    private let connectivityProvider: PhoneConnectivityProvider
    
    init(characters: [String] = [], connectivityProvider: PhoneConnectivityProvider) {
        self.characters = characters
        self.connectivityProvider = connectivityProvider
        refresh()
    }
    
    func refresh() {
        connectivityProvider.refreshAllCharacters { [weak self] (characters: [String]?) in
            guard let characters = characters else { return }
            self?.characters = characters
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let previewCharacters = ["Ja'Zakajirr", "Geetum-Za", "Malula", "Candella"]
        let characterList = CharacterList(characters: previewCharacters, connectivityProvider: PhoneConnectivityProvider())
        return ContentView(viewModel: characterList)
    }
}
