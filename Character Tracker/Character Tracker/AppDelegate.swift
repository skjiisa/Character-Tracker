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
            
            do {
                // Temporary method of preloading basic data until a proper method is implemented
                let context = CoreDataStack.shared.mainContext

                let attributeTypes: [(name: String, id: UUID)] = [
                    ("Skill", UUID(uuidString: "9515BBFA-A1B9-43E4-BBDB-D946C8C2FD54")!),
                    ("Objective", UUID(uuidString: "0603FAB8-2053-4A7F-A01F-F825B687AB6B")!)
                ]

                for tuplet in attributeTypes {
                    let attributeType = AttributeType(context: context)
                    attributeType.id = tuplet.id
                    attributeType.name = tuplet.name
                }
                
                let games: [(name: String, index: Int16, mainline: Bool, id: UUID)] = [
                    ("Skyrim", 4, true, UUID(uuidString: "33839302-E5B9-4299-AA81-444BED243F20")!),
                    ("Daggerfall", 1, true, UUID(uuidString: "620A5BF0-648A-404A-AD6D-8E6D4F9994BE")!),
                    ("Elder Scrolls Online", 5, false, UUID(uuidString: "432650F5-26F6-491F-8280-5F3B0386C038")!)
                ]
                
                for tuplet in games {
                    let game = Game(context: context)
                    game.id = tuplet.id
                    game.name = tuplet.name
                    game.index = tuplet.index
                    game.mainline = tuplet.mainline
                }

                try context.save()
                
                // Below is a failed attempt to preload an existing .sqlite database extracted from a simulator
//                let fileManager = FileManager.default
//                guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
//
//                let databaseURL = applicationSupport.appendingPathComponent("Character_Tracker.sqlite")
//
//                print(databaseURL)
//
//                guard let dbFilePath = Bundle.main.url(forResource: "Character_Tracker", withExtension: "sqlite") else { return }
//
//                let dbFile = try FileHandle(forReadingFrom: dbFilePath)
//
//                print(dbFile)
//                let data = dbFile.readDataToEndOfFile()
//                try data.write(to: databaseURL)
//
                userDefaults.set(true, forKey: preloadedDataKey)
            } catch {
                fatalError("Undable to preload data: \(error)")
            }
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

