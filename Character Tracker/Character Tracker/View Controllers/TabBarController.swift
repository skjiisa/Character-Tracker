//
//  TabBarController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    
    let gameReference = GameReference()
    let attributeTypeController = AttributeTypeController()
    let moduleTypeController = ModuleTypeController()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let viewControllers = viewControllers {
            for vc in viewControllers {
                if let navigationVC = vc as? UINavigationController {
                    for vc in navigationVC.viewControllers {
                        
                        if let characterTrackerVC = vc as? CharacterTrackerViewController {
                            characterTrackerVC.gameReference = gameReference
                            
                            if let settingsVC = characterTrackerVC as? SettingsTableViewController {
                                settingsVC.attributeTypeController = attributeTypeController
                                settingsVC.moduleTypeController = moduleTypeController
                            } else if let charactersVC = characterTrackerVC as? CharactersTableViewController {
                                charactersVC.attributeTypeController = attributeTypeController
                            }
                            
                        }
                        
                    }
                }
            }
        }
    }
    
}
