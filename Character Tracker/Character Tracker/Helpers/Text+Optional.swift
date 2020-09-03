//
//  Text+Optional.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/2/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

extension Text {
    init?(optionalString: String?) {
        guard let string = optionalString else { return nil }
        self.init(string)
    }
}
