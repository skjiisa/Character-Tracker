//
//  Character_Tracker+Convenience.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

extension Race {
    @discardableResult convenience init(name: String, vanilla: Bool, id: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.name = name
        self.id = id
        self.vanilla = vanilla
    }
}
