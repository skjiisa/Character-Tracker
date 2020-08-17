//
//  CharacterTrackerViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/17/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import UIKit

protocol CharacterTrackerViewController: UIViewController, ScannerViewControllerDelegate {
    var gameReference: GameReference? { get set }
}

//MARK: Scanner view controller delegate

extension CharacterTrackerViewController {
    func found(code: String) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dismiss(animated: true) {
            dispatchGroup.leave()
        }
        
        let context = CoreDataStack.shared.container.newBackgroundContext()
        
        context.performAndWait {
            let importedNames = PortController.shared.importOnBackgroundContext(string: code, context: context)
            
            let alert = UIAlertController(title: "Imported objects", message: importedNames.joined(separator: ", "), preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            let save = UIAlertAction(title: "Save", style: .default) { _ in
                CoreDataStack.shared.save(context: context)
            }
            
            alert.addAction(cancel)
            alert.addAction(save)
            
            dispatchGroup.notify(queue: .main, execute: {
                self.present(alert, animated: true)
            })
        }
    }
}
