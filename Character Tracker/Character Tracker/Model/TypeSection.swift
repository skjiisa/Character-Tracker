//
//  TypeSection.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import Foundation

protocol TypeSection {
    var name: String? { get set }
    var id: UUID? { get set }
    var typeName: String { get }
}

class TempSection {
    var section: TypeSection
    var collapsed: Bool
    
    init(section: TypeSection, collapsed: Bool = false) {
        self.section = section
        self.collapsed = collapsed
    }
}

class TempSectionRepresentation: Codable {
    var section: UUID
    var collapsed: Bool
    
    init?(tempSection: TempSection) {
        guard let id = tempSection.section.id else { return nil }
        self.section = id
        self.collapsed = tempSection.collapsed
    }
}
