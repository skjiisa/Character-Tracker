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
    
    init() {
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
    
    func subsection(for section: Int, types: [AttributeType]) -> (type: AttributeType, minPriority: Int16, maxPriority: Int16)? {
        var i = 0
        
        if section == 0 {
            return nil
        }
        
        var attributeType: AttributeType?
        var priority: Int16?
        
        for type in types {
            let sectionsForType = self.sectionsForType(type)
            if section <= i + sectionsForType.count {
                attributeType = type
                priority = Int16(section - i - 1)
                break
            } else {
                i += sectionsForType.count
            }
        }
        
        guard let unwrappedAttributeType = attributeType,
            let unwrappedPriority = priority else { return nil }
        
        return (unwrappedAttributeType, unwrappedPriority, unwrappedPriority)
    }
    
    func sectionsForType(_ type: AttributeType) -> [AttributeTypeSection] {
        return sections.filter({ $0.type == type })
    }
}
