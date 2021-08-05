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
        tempLinks = (module.links as? Set<ExternalLink>)?.sorted(by: { $0.wrappedName < $1.wrappedName }) ?? []
    }
    
    func newLink(for module: Module, context moc: NSManagedObjectContext) {
        let link = ExternalLink(context: moc)
        link.modules = [module]
        tempLinks = (tempLinks + [link]).sorted(by: { $0.wrappedName < $1.wrappedName })
    }
    
    private func remove(links: [ExternalLink], context moc: NSManagedObjectContext, remove: (ExternalLink) -> Void) {
        let indicesToRemove: [Int] = links.compactMap { link in
            remove(link)
            deleteIfUnused(link, context: moc)
            return tempLinks.firstIndex(of: link)
        }
        
        tempLinks.remove(atOffsets: IndexSet(indicesToRemove))
    }
    
    func remove(links: [ExternalLink], from module: Module, context moc: NSManagedObjectContext) {
        remove(links: links, context: moc) { $0.mutableSetValue(forKey: "modules").remove(module) }
    }
    
    func remove(links: [ExternalLink], from mod: Mod, context moc: NSManagedObjectContext) {
        remove(links: links, context: moc) { $0.mutableSetValue(forKey: "mods").remove(mod) }
    }
    
    func deleteIfUnused(_ link: ExternalLink, context moc: NSManagedObjectContext) {
        if ["attributes", "authors", "games", "ingredients", "mods", "modules", "races"].compactMap({ (link.value(forKey: $0) as? NSSet)?.anyObject() }).isEmpty {
            moc.delete(link)
        }
    }
}
