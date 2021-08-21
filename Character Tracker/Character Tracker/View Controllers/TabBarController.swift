//
//  TabBarController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import SwiftUI

class TabBarController: UITabBarController {
    
    let gameReference = GameReference()
    let attributeTypeController = AttributeTypeController()
    let moduleTypeController = ModuleTypeController()
    let modController = ModController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pass in controllers
        viewControllers?
            .compactMap { ($0 as? UINavigationController)?.viewControllers }
            .flatMap { $0 }
            .compactMap { $0 as? CharacterTrackerViewController }
            .forEach { vc in
                vc.gameReference = gameReference
                
                if let settingsVC = vc as? SettingsTableViewController {
                    settingsVC.attributeTypeController = attributeTypeController
                    settingsVC.moduleTypeController = moduleTypeController
                } else if let charactersVC = vc as? CharactersTableViewController {
                    charactersVC.attributeTypeController = attributeTypeController
                }
            }
        
        // Add mods view
        let modsViewHost = UIHostingController(rootView:
            NavigationView {
                ModsViewContainer()
                    .environment(\.managedObjectContext, CoreDataStack.shared.mainContext)
                    .environmentObject(modController)
                    .environmentObject(gameReference)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        )
        modsViewHost.tabBarItem.title = "Mods"
        modsViewHost.tabBarItem.image = UIImage(systemName: "circle.grid.hex.fill")
        viewControllers?.insert(modsViewHost, at: 1)
    }

}
