//
//  AttributesTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import CoreData

class AttributesTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var addAttributeButton: UIButton!
    @IBOutlet weak var addAttributeView: UIView!
    
    //MARK: Properties
    
    var attributeController: AttributeController?
    var attributeType: AttributeType?
    var checkedAttributes: [Attribute] = []
    var gameReference: GameReference?
    var showAll = false
    var callbacks: [( (Attribute) -> Void )] = []
    
    var attributeName: String {
        if let name = attributeType?.name {
            return name.capitalized
        } else {
            return "Attribute"
        }
    }
    
    func choose(attribute: Attribute) {
        for callback in callbacks {
            callback(attribute)
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Attribute>? = {
        
        let fetchRequest: NSFetchRequest<Attribute> = Attribute.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        guard let game = gameReference?.game,
            let type = attributeType else { return nil }
        
        if !showAll {
            fetchRequest.predicate = NSPredicate(format: "ANY game == %@ AND type == %@", game, type)
        } else {
            if let gameAttributes = game.attributes {
                fetchRequest.predicate = NSPredicate(format: "NOT (SELF in %@) AND type == %@", gameAttributes, type)
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
            fatalError("Error performing fetch for attribute frc: \(error)")
        }
        
        return frc
    }()
    
    lazy var gamesFRC: NSFetchedResultsController<Game> = {
        let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: CoreDataStack.shared.mainContext,
                                             sectionNameKeyPath: "name",
                                             cacheName: nil)
                
        do {
            try frc.performFetch()
        } catch {
            fatalError("Error performing fetch for race frc: \(error)")
        }
        
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        title = "\(attributeName)s"
        addAttributeButton.setTitle("Add \(attributeName)", for: .normal)
        
        if showAll {
            addAttributeView.isHidden = true
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
        let cell: UITableViewCell
        
        guard let attribute = fetchedResultsController?.object(at: indexPath) else {
            cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath)
            return cell
        }
        
        if !showAll {
            cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "AttributeGamesCell", for: indexPath)
            if let allGames = gamesFRC.fetchedObjects,
                let game = gameReference?.game {
                let games = allGames.filter({ ($0.attributes?.contains(attribute) ?? false) && $0 != game })
                let gameNames = games.compactMap({ $0.name })
                cell.detailTextLabel?.text = gameNames.joined(separator: ", ")
            }
        }

        cell.textLabel?.text = attribute.name
        
        if checkedAttributes.contains(attribute) {
            cell.accessoryType = .checkmark
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

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        print("ayy lmao")
        if editingStyle == .delete {
            print("delete")
            if let attribute = fetchedResultsController?.object(at: indexPath) {
                if attribute.game?.count ?? 0 > 1, // If this race is tied
                    !showAll { // and you aren't in the master list
                    guard let game = gameReference?.game else { return }
                    attributeController?.remove(game: game, from: attribute, context: CoreDataStack.shared.mainContext)
                } else {
                    attributeController?.delete(attribute: attribute, context: CoreDataStack.shared.mainContext)
                }
            }
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let attribute = fetchedResultsController?.object(at: indexPath) else { return }
        
        if !showAll {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if let cell = tableView.cellForRow(at: indexPath) {
                if cell.accessoryType == .none {
                    cell.accessoryType = .checkmark
                    choose(attribute: attribute)
                } else {
                    cell.accessoryType = .none
                    attributeController?.remove(tempAttribute: attribute)
                }
            }
        } else {
            choose(attribute: attribute)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let attributesVC = segue.destination as? AttributesTableViewController {
            attributesVC.showAll = true
            attributesVC.gameReference = gameReference
            attributesVC.attributeController = attributeController
            attributesVC.attributeType = attributeType
            attributesVC.callbacks.append { attribute in
                guard let game = self.gameReference?.game else { return }
                self.attributeController?.add(game: game, to: attribute, context: CoreDataStack.shared.mainContext)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    //MARK: Actions
    
    @IBAction func addAttribute(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add \(attributeName)", message: nil, preferredStyle: .actionSheet)
        
        let addExisting = UIAlertAction(title: "Add existing \(attributeName)", style: .default) { _ in
            self.performSegue(withIdentifier: "ModalShowAttributes", sender: self)
        }
        
        let addNew = UIAlertAction(title: "Add new \(attributeName)", style: .default) { _ in
            self.showNewAttributeAlert()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addExisting)
        alertController.addAction(addNew)
        alertController.addAction(cancelAction)
        
        alertController.pruneNegativeWidthConstraints()
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showNewAttributeAlert() {
        guard let game = gameReference?.game,
            let type = attributeType else { return }
        
        let alertController = UIAlertController(title: "New \(attributeName)", message: "", preferredStyle: .alert)
        
        let saveVanilla = UIAlertAction(title: "Save", style: .default) { (_) in
            guard let name = alertController.textFields?[0].text else { return }
            
            self.attributeController?.create(attribute: name, game: game, type: type, context: CoreDataStack.shared.mainContext )
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "\(self.attributeName) name"
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

extension AttributesTableViewController: NSFetchedResultsControllerDelegate {
    
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
