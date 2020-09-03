//
//  ModuleDetailView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/2/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ModuleDetailView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController
    
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var gameReference: GameReference
    var moduleController = ModuleController()
    
    var module: Module
    var character: Character? = nil
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        // Note that this is a navigation controller meant to be shown in a sheet
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let moduleDetailVC = storyboard.instantiateViewController(withIdentifier: "ModuleDetail") as! ModuleDetailTableViewController
        
        moduleDetailVC.gameReference = gameReference
        moduleDetailVC.moduleType = module.type
        moduleDetailVC.module = module
        
        if let character = character {
            let characterModules = character.modules as? Set<CharacterModule>
            moduleDetailVC.characterModule = characterModules?.first(where: { $0.module == module })
        }
        
        moduleDetailVC.callbacks.append { characterModule, completed in
            self.moduleController.setCompleted(characterModule: characterModule, completed: completed, context: self.moc)
            if completed {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        
        let navigationVC = UINavigationController(rootViewController: moduleDetailVC)
        
        return navigationVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
