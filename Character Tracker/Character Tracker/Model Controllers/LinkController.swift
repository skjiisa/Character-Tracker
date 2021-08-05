//
//  LinkController.swift
//  Character Tracker
//
//  Created by Elaine Lyons on 8/3/21.
//

import CoreData

class LinkController: ObservableObject {
    var tempLinks: [ExternalLink] = []
    
    func fetchTempLinks(for module: Module) {
        tempLinks = (module.links as? Set<ExternalLink>)?.sorted(by: { $0.wrappedName > $1.wrappedName }) ?? []
    }
    
    func newLink(for module: Module, context moc: NSManagedObjectContext) {
        let link = ExternalLink(context: moc)
        link.modules = [module]
    }
    
    func remove(links: [ExternalLink], from module: Module, context moc: NSManagedObjectContext) {
        links.forEach { link in
            link.mutableSetValue(forKey: "modules").remove(module)
            deleteIfUnused(link, context: moc)
        }
    }
    
    func remove(links: [ExternalLink], from mod: Mod, context moc: NSManagedObjectContext) {
        links.forEach { link in
            link.mutableSetValue(forKey: "mods").remove(mod)
            deleteIfUnused(link, context: moc)
        }
    }
    
    func deleteIfUnused(_ link: ExternalLink, context moc: NSManagedObjectContext) {
        if ["attributes", "authors", "games", "ingredients", "mods", "modules", "races"].compactMap({ (link.value(forKey: $0) as? NSSet)?.anyObject() }).isEmpty {
            moc.delete(link)
        }
    }
}
