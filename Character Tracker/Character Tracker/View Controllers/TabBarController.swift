//
//  TabBarController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

protocol CharacterTrackerViewController: UIViewController {
    var gameReference: GameReference? { get set }
}

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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
