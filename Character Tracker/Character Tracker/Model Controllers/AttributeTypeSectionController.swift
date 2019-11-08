//
//  AttributeTypeSectionController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/6/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class AttributeTypeSectionController {
    var sections: [AttributeTypeSection] = []
    var tempSectionsToShow: [AttributeTypeSection] = []
    var sectionsByCharacter: [Character: [AttributeTypeSection]] = [:]
    
    init() {
        loadFromPersistentStore()
        do {
            let fetchRequest: NSFetchRequest<AttributeTypeSection> = AttributeTypeSection.fetchRequest()
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "type", ascending: true),
                NSSortDescriptor(key: "minPriority", ascending: true)
            ]
            
            let allSections = try CoreDataStack.shared.mainContext.fetch(fetchRequest)
            self.sections = allSections
        } catch {
            NSLog("Could not fetch attribute type sections: \(error)")
        }
    }
    
    func sectionToShow(_ index: Int) -> AttributeTypeSection? {
        let section = index - 1
        if section >= 0,
            section < tempSectionsToShow.count {
            return tempSectionsToShow[section]
        }
        return nil
    }
    
    func clearTempSections() {
        tempSectionsToShow = []
    }
    
    func saveTempSections(to character: Character) {
        sectionsByCharacter[character] = tempSectionsToShow
        clearTempSections()
        saveToPersistentStore()
    }
    
    func loadTempSections(for character: Character) {
        tempSectionsToShow = sectionsByCharacter[character] ?? []
    }
    
    func saveToPersistentStore() {
        
    }
    
    func loadFromPersistentStore() {
        
    }
}
