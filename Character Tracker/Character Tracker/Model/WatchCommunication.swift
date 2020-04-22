//
//  WatchCommunication.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import Foundation

struct WatchCommunication {
    static let requestKey = "request"
    static let responseKey = "response"
    
    enum Content: String {
        case allCharacters
    }
}
