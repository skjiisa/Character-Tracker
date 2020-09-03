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
    
    @EnvironmentObject var gameReference: GameReference
    
    var module: Module
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        // Note that this is a navigation controller meant to be shown in a sheet
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let moduleDetailVC = storyboard.instantiateViewController(withIdentifier: "ModuleDetail") as! ModuleDetailTableViewController
        
        moduleDetailVC.gameReference = gameReference
        moduleDetailVC.moduleType = module.type
        moduleDetailVC.module = module
        
        let navigationVC = UINavigationController(rootViewController: moduleDetailVC)
        
        return navigationVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
