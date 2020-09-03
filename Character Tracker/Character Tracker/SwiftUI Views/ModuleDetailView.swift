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
    var characterModule: CharacterModule? = nil
    
    init(module: Module) {
        self.module = module
    }
    
    init(characterModule: CharacterModule) {
        self.module = characterModule.module!
        self.characterModule = characterModule
    }
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        // Note that this is a navigation controller meant to be shown in a sheet
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let moduleDetailVC = storyboard.instantiateViewController(withIdentifier: "ModuleDetail") as! ModuleDetailTableViewController
        
        moduleDetailVC.gameReference = gameReference
        moduleDetailVC.moduleType = module.type
        moduleDetailVC.module = module
        moduleDetailVC.characterModule = characterModule
        
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
