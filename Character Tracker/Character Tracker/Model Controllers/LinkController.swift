//
//  LinkController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/3/21.
//  Copyright © 2021 Isaac Lyons. All rights reserved.
//

import CoreData

class LinkController {
    var tempLinks: [ExternalLink] = []
    
    func fetchTempLinks(for module: Module, context: NSManagedObjectContext) {
        tempLinks = (module.links as? Set<ExternalLink>)?.sorted(by: { $0.wrappedName < $1.wrappedName }) ?? []
    }
}
