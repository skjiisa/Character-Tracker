//
//  LinkController.swift
//  Character Tracker
//
//  Created by Elaine Lyons on 8/3/21.
//

import CoreData

class LinkController {
    var tempLinks: [ExternalLink] = []
    
    func fetchTempLinks(for module: Module) {
        tempLinks = (module.links as? Set<ExternalLink>)?.sorted(by: { $0.wrappedName > $1.wrappedName }) ?? []
    }
    
    func newLink(for module: Module, context moc: NSManagedObjectContext) {
        let link = ExternalLink(context: moc)
        link.modules = [module]
    }
}
