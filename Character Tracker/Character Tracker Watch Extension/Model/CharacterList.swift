//
//  CharacterList.swift
//  Character Tracker Watch Extension
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import Foundation

final class CharacterList: ObservableObject {
    @Published private(set) var characters: [CharacterRepresentation]
    
    private let connectivityProvider: PhoneConnectivityProvider
    
    init(characters: [CharacterRepresentation] = [], connectivityProvider: PhoneConnectivityProvider) {
        self.characters = characters
        self.connectivityProvider = connectivityProvider
        connectivityProvider.delegate = self
    }
}

//MARK: Phone connectivity provider delegate

extension CharacterList: PhoneConnectivityProviderDelegate {
    func refresh() {
        connectivityProvider.refreshAllCharacters { [weak self] (characters: [CharacterRepresentation]?) in
            guard let characters = characters else { return }
            self?.characters = characters
        }
    }
}
