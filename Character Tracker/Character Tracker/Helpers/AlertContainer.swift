//
//  AlertContainer.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/31/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

class AlertContainer: Identifiable {
    var alert: Alert
    
    init(_ alert: Alert) {
        self.alert = alert
    }
}
