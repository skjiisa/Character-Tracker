//
//  Section.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import Foundation

protocol Section {
    var name: String? { get set }
    var id: UUID? { get set }
    var typeName: String { get }
}

class TempSection {
    var section: Section
    var collapsed: Bool
    
    init(section: Section, collapsed: Bool = false) {
        self.section = section
        self.collapsed = collapsed
    }
}
