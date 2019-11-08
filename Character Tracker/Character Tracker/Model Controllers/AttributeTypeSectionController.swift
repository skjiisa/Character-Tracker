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
        loadFromPersistentStore()
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
    
    //MARK: Persistent Store
    
    private var persistentFileURL: URL? {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        return documents.appendingPathComponent("sections.plist")
    }
    
    func saveToPersistentStore() {
        guard let url = persistentFileURL else { return }
        
        var sectionsByCharacterID: [UUID: [UUID]] = [:]
        
        for character in sectionsByCharacter {
            guard let sections = sectionsByCharacter[character.key],
                let characterID = character.key.id else { continue }
            
            let sectionIDs = sections.compactMap({ $0.id })
            sectionsByCharacterID[characterID] = sectionIDs
        }
        
        do {
            let data = try PropertyListEncoder().encode(sectionsByCharacterID)
            try data.write(to: url)
            print(sectionsByCharacterID)
        } catch {
            NSLog("Error loading sections data: \(error)")
        }
    }
    
    func loadFromPersistentStore() {
        let fileManager = FileManager.default
        guard let url = persistentFileURL,
            fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let sectionsByCharacterID = try PropertyListDecoder().decode([UUID: [UUID]].self, from: data)
            
            let charactersFetchRequest: NSFetchRequest<Character> = Character.fetchRequest()
            let allCharacters = try CoreDataStack.shared.mainContext.fetch(charactersFetchRequest)
            
            for characterID in sectionsByCharacterID {
                guard let character = allCharacters.first(where: { $0.id == characterID.key }) else { continue }
                
                var sections: [AttributeTypeSection] = []
                for sectionID in characterID.value {
                    guard let section = self.sections.first(where: { $0.id == sectionID }) else { continue }
                    sections.append(section)
                }
                
                self.sectionsByCharacter[character] = sections
            }
        } catch {
            print("Error loading sections data: \(error)")
        }
    }
}
