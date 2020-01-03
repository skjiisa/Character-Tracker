//
//  AppDelegate.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        preloadData()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    private func preloadData() {
        let preloadedDataKey = "didPreloadData"
        
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: preloadedDataKey) {

            JSONController.preloadData()
            
            /*
            do {
                // Temporary method of preloading basic data until a proper method is implemented
                let context = CoreDataStack.shared.mainContext

                let attributeTypes: [(name: String, id: UUID)] = [
                    ("skill", UUID(uuidString: "9515BBFA-A1B9-43E4-BBDB-D946C8C2FD54")!),
                    ("combat style", UUID(uuidString: "C7D6EF66-DA61-480F-9508-13D1EF65F768")!),
                    ("armor type", UUID(uuidString: "DF9C65E2-B917-4C45-AB0E-BCC7C645B3A8")!)
                ]
                
                var types: [AttributeType] = []

                for tuplet in attributeTypes {
                    let attributeType = AttributeType(context: context)
                    attributeType.id = tuplet.id
                    attributeType.name = tuplet.name
                    
                    types.append(attributeType)
                }
                
                let attributeTypeSections: [(name: String, type: Int, priority: Int16, id: UUID)] = [
                    ("Primary Skills", 0, 0, UUID(uuidString: "9FBF5691-B7FA-4DFD-BFEE-4AD5CCC673C4")!),
                    ("Major Skills", 0, 1, UUID(uuidString: "74AC8FAF-3004-4CAD-B442-D89AA571A2B7")!),
                    ("Minor Skills", 0, 2, UUID(uuidString: "1435E225-54B8-4FED-879E-9F08CB2EFB9F")!),
                    ("Primary Combat Style", 1, 0, UUID(uuidString: "1B69AADC-34E3-4067-9C83-FF78F7ECE2F3")!),
                    ("Secondary Combat Style", 1, 1, UUID(uuidString: "D8555224-80E1-4565-8349-4A1409AB1B31")!),
                    ("Armor Type", 2, 0, UUID(uuidString: "FC6F42BB-0CD0-4C54-8ED7-A5FEDB4F50D4")!)
                ]
                
                for tuplet in attributeTypeSections {
                    let section = AttributeTypeSection(context: context)
                    section.name = tuplet.name
                    section.type = types[tuplet.type]
                    section.maxPriority = tuplet.priority
                    section.minPriority = tuplet.priority
                    section.id = tuplet.id
                }
                
                let games: [(name: String, index: Int16, mainline: Bool, id: UUID)] = [
                    ("Skyrim", 4, true, UUID(uuidString: "33839302-E5B9-4299-AA81-444BED243F20")!),
                    ("Daggerfall", 1, true, UUID(uuidString: "620A5BF0-648A-404A-AD6D-8E6D4F9994BE")!),
                    ("Elder Scrolls Online", 5, false, UUID(uuidString: "432650F5-26F6-491F-8280-5F3B0386C038")!),
                    ("Enderal", 5, false, UUID(uuidString: "4FBBD913-FCAB-43AC-B88B-5932EEB7983C")!)
                ]
                
                for tuplet in games {
                    let game = Game(context: context)
                    game.id = tuplet.id
                    game.name = tuplet.name
                    game.index = tuplet.index
                    game.mainline = tuplet.mainline
                }
                
                let moduleTypes: [(name: String, id: UUID)] = [
                    ("Questline", UUID(uuidString: "60A0B797-9326-44C1-BB79-0B2F6AF8231E")!),
                    ("Objective", UUID(uuidString: "E80837B9-4F26-41BA-93ED-A1ED46A88A05")!),
                    ("Follower", UUID(uuidString: "5DC0190E-4F18-4B72-8E24-B1DE80569BE4")!),
                    ("Equipment", UUID(uuidString: "EA1A35DB-3165-45F0-A55D-A94D5B5DA6BE")!),
                    ("House", UUID(uuidString: "D453D642-DE13-41F2-B129-A89D447E2863")!)
                ]
                
                for tuplet in moduleTypes {
                    let moduleType = ModuleType(context: context)
                    moduleType.name = tuplet.name
                    moduleType.id = tuplet.id
                }

                try context.save()
                
                userDefaults.set(true, forKey: preloadedDataKey)
            } catch {
                fatalError("Undable to preload data: \(error)")
            }
            */
        }
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Character_Tracker")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

