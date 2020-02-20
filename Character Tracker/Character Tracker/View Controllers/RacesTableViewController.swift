//
//  RacesTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import CoreData

class RacesTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var addRaceView: UIView!
    
    //MARK: Properties
    
    var raceController = RaceController()
    var gameReference: GameReference?
    var showAll = false
    var callbacks: [( (Race) -> Void )] = []
    
    func choose(race: Race) {
        for callback in callbacks {
            callback(race)
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Race>? = {
        
        let fetchRequest: NSFetchRequest<Race> = Race.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        guard let game = gameReference?.game else { return nil }
        
        if !showAll {
            fetchRequest.predicate = NSPredicate(format: "ANY games == %@", game)
        } else {
            if let gameRaces = game.races {
                fetchRequest.predicate = NSPredicate(format: "NOT SELF in %@", gameRaces)
            }
        }
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: CoreDataStack.shared.mainContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            fatalError("Error performing fetch for race frc: \(error)")
        }
        
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if showAll {
            addRaceView.isHidden = true
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if fetchedResultsController?.sectionIndexTitles[section] == "1" {
//            return "Vanilla"
//        } else {
//            return "Custom"
//        }
//    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RaceCell", for: indexPath)
        
        let race = fetchedResultsController?.object(at: indexPath)
        
        cell.textLabel?.text = race?.name
        
        if showAll,
            let gameNames = race?.games?.compactMap({ ($0 as? Game)?.name }) {
            cell.detailTextLabel?.text = gameNames.joined(separator: ", ")
        } else {
            cell.detailTextLabel?.text = nil
        }

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let race = fetchedResultsController?.object(at: indexPath) else { return }
            
            if race.games?.count ?? 0 > 1, // If this race is tied to other games
                !showAll { // and you aren't in the master list
                guard let game = gameReference?.game else { return }
                raceController.remove(game: game, from: race, context: CoreDataStack.shared.mainContext)
            } else {
                raceController.delete(race: race, context: CoreDataStack.shared.mainContext)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let race = fetchedResultsController?.object(at: indexPath) else { return }
        
        choose(race: race)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let racesVC = segue.destination as? RacesTableViewController {
            racesVC.showAll = true
            racesVC.gameReference = gameReference
            racesVC.callbacks.append { race in
                guard let game = self.gameReference?.game else { return }
                self.raceController.add(game: game, to: race, context: CoreDataStack.shared.mainContext)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    //MARK: Actions
    
    @IBAction func addRace(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add Race", message: nil, preferredStyle: .actionSheet)
        
        let addExisting = UIAlertAction(title: "Add existing race", style: .default) { _ in
            self.performSegue(withIdentifier: "ModalShowRaces", sender: self)
        }
        
        let addNew = UIAlertAction(title: "Add new race", style: .default) { _ in
            self.showNewRaceAlert()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addNew)
        alertController.addAction(addExisting)
        alertController.addAction(cancelAction)
        
        alertController.pruneNegativeWidthConstraints()
                
        present(alertController, animated: true, completion: nil)
    }
    
    private func showNewRaceAlert() {
        guard let game = gameReference?.game else { return }
        
        let alertController = UIAlertController(title: "New Race", message: "", preferredStyle: .alert)
        
        let saveVanilla = UIAlertAction(title: "Save", style: .default) { (_) in
            guard let name = alertController.textFields?[0].text else { return }
            
            self.raceController.create(race: name, game: game, context: CoreDataStack.shared.mainContext )
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Race name"
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
        }
                
        alertController.addAction(saveVanilla)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}

//MARK: Fetched Results Controller Delegate

extension RacesTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        case .move:
            guard let indexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            
            tableView.moveRow(at: indexPath, to: newIndexPath)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        @unknown default:
            fatalError()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default:
            return
        }
    }
}
