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
