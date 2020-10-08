//
//  AttributeTypeSectionController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/6/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import CoreData

class AttributeTypeSectionController {
    var sections: [TypeSection] = []
    var tempSectionsToShow: [TempSection] = []
    var sectionsByCharacter: [Character: [TempSection]] = [:]
    var defaultSectionsByGame: [Game: [TempSection]] = [:]
    
    init() {
        do {
            let sectionsFetchRequest: NSFetchRequest<AttributeTypeSection> = AttributeTypeSection.fetchRequest()
            sectionsFetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "type", ascending: true),
                NSSortDescriptor(key: "minPriority", ascending: true)
            ]
            
            let allSections = try CoreDataStack.shared.mainContext.fetch(sectionsFetchRequest)
            self.sections = allSections
            
            let moduleTypesFetchRequest: NSFetchRequest<ModuleType> = ModuleType.fetchRequest()
            moduleTypesFetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "name", ascending: true)
            ]
            
            let allModuleTypes = try CoreDataStack.shared.mainContext.fetch(moduleTypesFetchRequest)
            self.sections.append(contentsOf: allModuleTypes)
        } catch {
            NSLog("Could not fetch attribute type sections: \(error)")
        }
        loadFromPersistentStore()
    }
    
    func sectionToShow(_ index: Int) -> TempSection? {
        var totalSections = 0
        
        for section in tempSectionsToShow {
            totalSections += 1
            
            if totalSections == index {
                return section
            } else if totalSections > index {
                return nil
            }
            
            if section.section is ModuleType {
                totalSections += 1
            }
        }
        return nil
    }
    
    func toggleSection(_ index: Int) {
        var totalSections = 0
        
        for i in 0..<tempSectionsToShow.count {
            let section = tempSectionsToShow[i]
            totalSections += 1
            
            if totalSections == index {
                section.collapsed.toggle()
                return
            } else if totalSections > index {
                return
            }
            
            if section.section is ModuleType {
                totalSections += 1
            }
        }
    }
    
    func saveTempSections(to character: Character) {
        sectionsByCharacter[character] = tempSectionsToShow
        saveToPersistentStore()
    }
    
    func saveTempSections(to game: Game) {
        defaultSectionsByGame[game] = tempSectionsToShow
        saveToPersistentStore()
    }
    
    func loadTempSections(for character: Character) {
        tempSectionsToShow = sectionsByCharacter[character] ?? []
    }
    
    func loadTempSections(for game: Game) {
        loadFromPersistentStore()
        tempSectionsToShow = defaultSectionsByGame[game] ?? []
    }
    
    func contains(section: TypeSection) -> Bool {
        for item in tempSectionsToShow {
            if let inputAttributeTypeSection = section as? AttributeTypeSection {
                if let itemAttributeTypeSection = item.section as? AttributeTypeSection,
                    inputAttributeTypeSection == itemAttributeTypeSection {
                    return true
                }
            } else if let inputModuleType = section as? ModuleType {
                if let itemModuleType = item.section as? ModuleType,
                    inputModuleType == itemModuleType {
                    return true
                }
            }
        }
        return false
    }
    
    func remove(section: TypeSection) {
        for i in 0..<tempSectionsToShow.count {
            if let inputAttributeTypeSection = section as? AttributeTypeSection {
                if let iAttributeTypeSection = tempSectionsToShow[i].section as? AttributeTypeSection,
                    inputAttributeTypeSection == iAttributeTypeSection {
                    tempSectionsToShow.remove(at: i)
                    return
                }
            } else if let inputModuleType = section as? ModuleType {
                if let iModuleType = tempSectionsToShow[i].section as? ModuleType,
                    inputModuleType == iModuleType {
                    tempSectionsToShow.remove(at: i)
                    return
                }
            }
        }
    }
    
    //MARK: Persistent Store
    
    private enum FileNames: String {
        case sections
        case defaults
    }
    
    private func persistentFileURL(file: FileNames) -> URL? {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        return documents.appendingPathComponent("\(file.rawValue).plist")
    }
    
    func saveToPersistentStore() {
        guard let sectionsUrl = persistentFileURL(file: .sections),
            let defaultsUrl = persistentFileURL(file: .defaults) else { return }
        
        var sectionsByCharacterID: [UUID: [TempSectionRepresentation]] = [:]
        var sectionsByGameID: [UUID: [TempSectionRepresentation]] = [:]
        
        // Extract IDs for characters
        for character in sectionsByCharacter {
            guard let sections = sectionsByCharacter[character.key],
                let characterID = character.key.id else { continue }
            
            let sectionRepresentations = sections.compactMap({ TempSectionRepresentation(tempSection: $0) })
            sectionsByCharacterID[characterID] = sectionRepresentations
        }
        
        // Extract IDs for games
        for game in defaultSectionsByGame {
            guard let sections = defaultSectionsByGame[game.key],
                let gameID = game.key.id else { continue }
            
            let sectionRepresentations = sections.compactMap({ TempSectionRepresentation(tempSection: $0) })
            sectionsByGameID[gameID] = sectionRepresentations
        }
        
        do {
            let charactersData = try PropertyListEncoder().encode(sectionsByCharacterID)
            try charactersData.write(to: sectionsUrl)
            
            let gamesData = try PropertyListEncoder().encode(sectionsByGameID)
            try gamesData.write(to: defaultsUrl)
        } catch {
            NSLog("Error loading sections data: \(error)")
        }
    }
    
    func loadFromPersistentStore() {
        let fileManager = FileManager.default
        guard let sectionsUrl = persistentFileURL(file: .sections),
              let defaultsUrl = persistentFileURL(file: .defaults),
              fileManager.fileExists(atPath: sectionsUrl.path),
              fileManager.fileExists(atPath: defaultsUrl.path) else {
            // No persistent store found. Initial app launch.
            // Set "Equipment" showing by default for the Skyrims
            
            do {
                guard let equipment = sections.first(where: { $0.id == UUID(uuidString: "EA1A35DB-3165-45F0-A55D-A94D5B5DA6BE") }) else { return }
                
                tempSectionsToShow.append(TempSection(section: equipment))
                
                let gamesFetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
                gamesFetchRequest.predicate = NSPredicate(format: "name CONTAINS[c] 'skyrim'")
                let games = try CoreDataStack.shared.mainContext.fetch(gamesFetchRequest)
                
                for game in games {
                    defaultSectionsByGame[game] = tempSectionsToShow
                }
                
                let charactersFetchRequest: NSFetchRequest<Character> = Character.fetchRequest()
                charactersFetchRequest.predicate = NSPredicate(format: "id == '8A1CD69A-4D4F-417A-B3A0-6ABE8A6C8C0E'")
                let characters = try CoreDataStack.shared.mainContext.fetch(charactersFetchRequest)
                if let character = characters.first {
                    sectionsByCharacter[character] = tempSectionsToShow
                }
                
                saveToPersistentStore()
            } catch {
                NSLog("Error setting default shown sections: \(error)")
            }
            
            return
        }
        
        do {
            // Decode characters
            let charactersData = try Data(contentsOf: sectionsUrl)
            let sectionsByCharacterID = try PropertyListDecoder().decode([UUID: [TempSectionRepresentation]].self, from: charactersData)

            let charactersFetchRequest: NSFetchRequest<Character> = Character.fetchRequest()
            let allCharacters = try CoreDataStack.shared.mainContext.fetch(charactersFetchRequest)

            for characterID in sectionsByCharacterID {
                guard let character = allCharacters.first(where: { $0.id == characterID.key }) else { continue }

                var sections: [TempSection] = []
                for tempSectionRepresentation in characterID.value {
                    guard let section = self.sections.first(where: { $0.id == tempSectionRepresentation.section }) else { continue }
                    sections.append(TempSection(section: section, collapsed: tempSectionRepresentation.collapsed))
                }

                self.sectionsByCharacter[character] = sections
            }
            
            // Decode games
            let gamesData = try Data(contentsOf: defaultsUrl)
            let sectionsByGameID = try PropertyListDecoder().decode([UUID: [TempSectionRepresentation]].self, from: gamesData)

            let gamesFetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
            let allGames = try CoreDataStack.shared.mainContext.fetch(gamesFetchRequest)

            for gameID in sectionsByGameID {
                guard let game = allGames.first(where: { $0.id == gameID.key }) else { continue }

                var sections: [TempSection] = []
                for tempSectionRepresentation in gameID.value {
                    guard let section = self.sections.first(where: { $0.id == tempSectionRepresentation.section }) else { continue }
                    sections.append(TempSection(section: section, collapsed: tempSectionRepresentation.collapsed))
                }

                self.defaultSectionsByGame[game] = sections
            }
        } catch {
            NSLog("Error loading sections data: \(error)")
        }
    }
}
