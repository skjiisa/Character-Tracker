//
//  GamesTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import CoreData

class GamesTableViewController: UITableViewController, CharacterTrackerViewController {
    
    var gameReference: GameReference?
    var checkedGames: [Game]?
    var callback: ( ([Game]) -> Void )?
    
    lazy var fetchedResultsController: NSFetchedResultsController<Game> = {
        
        let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "mainline", ascending: false),
            NSSortDescriptor(key: "index", ascending: false)
        ]
        
        if let game = gameReference?.game {
            fetchRequest.predicate = NSPredicate(format: "SELF != %@", game)
        }
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: CoreDataStack.shared.mainContext,
                                             sectionNameKeyPath: "mainline",
                                             cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            fatalError("Error performing fetch for frc: \(error)")
        }
        
        return frc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if checkedGames != nil {
            title = "Games"
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let checkedGames = checkedGames {
            callback?(checkedGames)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections?[section]
        return sectionInfo?.name == "1" ? "Mainline games" : "Others"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath)

        let game = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = game.name
        
        if checkedGames?.contains(game) ?? false {
            cell.accessoryType = .checkmark
            cell.detailTextLabel?.text = nil
        } else {
            cell.accessoryType = .none
            
            let charactersCount = game.characters?.count ?? 0
            if charactersCount > 0 {
                cell.detailTextLabel?.text = "\(charactersCount) character\(charactersCount == 1 ? "" : "s")"
            } else {
                cell.detailTextLabel?.text = nil
            }
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */
    
    //MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let game = fetchedResultsController.object(at: indexPath)
        
        if checkedGames != nil {
            tableView.deselectRow(at: indexPath, animated: true)
            let cell = tableView.cellForRow(at: indexPath)
            if checkedGames?.contains(game) ?? false {
                checkedGames?.removeAll(where: { $0 == game })
                cell?.accessoryType = .none
            } else {
                checkedGames?.append(game)
                cell?.accessoryType = .checkmark
            }
            //tableView.reloadRows(at: [indexPath], with: .automatic)
        } else {
            if gameReference?.isSafeToChangeGame ?? true {
                gameReference?.set(game: game)
            } else {
                let alertController = UIAlertController(title: "Are you sure?", message: "Changes to currently selected character will be lost.", preferredStyle: .alert)
                
                let continueAction = UIAlertAction(title: "Continue", style: .default) { _ in
                    self.gameReference?.set(game: game)
                    self.gameReference?.isSafeToChangeGame = true
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                alertController.addAction(continueAction)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true, completion: nil)
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
