//
//  ImageLinkController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/17/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import CoreData

class ImageLinkController: ObservableObject {
    
    func delete(_ imageLink: ImageLink, context: NSManagedObjectContext) {
        context.delete(imageLink)
        CoreDataStack.shared.save(context: context)
    }
    
    func remove(_ imageLink: ImageLink, from parent: OrderedImages?, context: NSManagedObjectContext) {
        if let parent = parent,
           // If more things get image sets, they'll have to be included here
           (imageLink.mods?.count ?? 0) + (imageLink.modules?.count ?? 0) > 1 {
            parent.mutableImages.remove(imageLink)
            CoreDataStack.shared.save(context: context)
        } else {
            delete(imageLink, context: context)
        }
    }
    
    func saveOrDeleteIfInvalid(_ imageLink: ImageLink, context: NSManagedObjectContext) {
        guard URL(string: imageLink.wrappedID) != nil else {
            return delete(imageLink, context: context)
        }
        
        if imageLink.mods?.anyObject() == nil,
            imageLink.modules?.anyObject() == nil {
            return delete(imageLink, context: context)
        }
        
        CoreDataStack.shared.save(context: context)
    }
    
}
