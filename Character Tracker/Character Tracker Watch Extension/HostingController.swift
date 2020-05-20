//
//  HostingController.swift
//  Character Tracker Watch Extension
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<ContentView> {
    lazy private(set) var connectivityProvider: PhoneConnectivityProvider = {
        let provider = PhoneConnectivityProvider()
        provider.connect()
        return provider
    }()
    
    private lazy var characterModel = CharacterList(connectivityProvider: connectivityProvider)
    
    override var body: ContentView {
        ContentView(characterList: characterModel)
    }
}
