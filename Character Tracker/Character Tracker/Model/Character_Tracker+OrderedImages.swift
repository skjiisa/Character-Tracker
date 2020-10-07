//
//  Character_Tracker+OrderedImages.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/5/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData

protocol OrderedImages: NSManagedObject {
    var images: NSOrderedSet? { get }
}

extension OrderedImages {
    var mutableImages: NSMutableOrderedSet {
        mutableOrderedSetValue(forKey: "images")
    }
}

extension Mod: OrderedImages {}

extension Module: OrderedImages {}
