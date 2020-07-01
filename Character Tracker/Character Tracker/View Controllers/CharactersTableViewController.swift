//
//  CharactersTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import CoreData

class CharactersTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Properties
    
    let characterController = CharacterController()
    var attributeTypeSectionController = AttributeTypeSectionController()
    var attributeTypeController: AttributeTypeController?
    var gameReference: GameReference? {
        didSet {
            gameReference?.callbacks.append {
                self.navigationController?.popToRootViewController(animated: false)
                self.changeGame()
                self.tableView.reloadData()
                self.navigationItem.title = self.gameReference?.name
            }
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Character>? = {
        let fetchRequest: NSFetchRequest<Character> = Character.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "modified", ascending: false)
        ]
        
        guard let game = gameReference?.game else { return nil }
        fetchRequest.predicate = NSPredicate(format: "game == %@", game)
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: CoreDataStack.shared.mainContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            fatalError("Error performing fetch for character frc: \(error)")
        }
        
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = gameReference?.name
        
        navigationItem.leftBarButtonItem = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        gameReference?.isSafeToChangeGame = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CharacterCell", for: indexPath)

        if let character = fetchedResultsController?.object(at: indexPath) {
            cell.textLabel?.text = character.name
            cell.detailTextLabel?.text = character.race?.name
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let character = fetchedResultsController?.object(at: indexPath) else { return }
            do {
                try characterController.delete(character: character, context: CoreDataStack.shared.mainContext)
            } catch {
                NSLog("Could not delete character: \(error)")
            }
        }
    }
    
    @IBAction func importJSON(_ sender: UIBarButtonItem) {
        JSONController.preloadData()
    }
    
    //MARK: Private
    
    private func changeGame() {
        guard let game = gameReference?.game else { return }
        fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "game == %@", game)
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            fatalError("Error performing fetch for character frc: \(error)")
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination: UIViewController
        
        if let navigationVC = segue.destination as? UINavigationController,
            let firstVC = navigationVC.viewControllers.first {
            destination = firstVC
        } else {
            destination = segue.destination
        }
        
        if let characterDetailVC = destination as? CharacterDetailTableViewController {
            characterDetailVC.gameReference = gameReference
            characterDetailVC.characterController = characterController
            characterDetailVC.attributeTypeController = attributeTypeController
            characterDetailVC.attributeTypeSectionController = attributeTypeSectionController
            guard let game = gameReference?.game else { return }
            characterDetailVC.attributeTypeSectionController?.loadTempSections(for: game)
            
            if segue.identifier == "ShowCharacterDetail",
                let indexPath = tableView.indexPathForSelectedRow {
                characterDetailVC.character = fetchedResultsController?.object(at: indexPath)
            } else {
                characterDetailVC.editMode = true
            }
        }
    }

}
