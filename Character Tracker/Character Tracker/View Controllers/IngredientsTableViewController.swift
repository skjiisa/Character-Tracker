//
//  IngredientsTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/15/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import CoreData

class IngredientsTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Properties
    
    var gameReference: GameReference?
    var ingredientController: IngredientController?
    var callbacks: [( (Ingredient) -> Void )] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    
    lazy var fetchedResultsController: NSFetchedResultsController<Ingredient> = {
        let fetchRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        fetchRequest.predicate = frcPredicate()
                
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: CoreDataStack.shared.mainContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            fatalError("Error performing fetch for ingredients frc: \(error)")
        }
        
        return frc
    }()
    
    //MARK: View loading

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)

        let ingredient = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = ingredient.name
        cell.detailTextLabel?.text = ingredient.id

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
        if editingStyle == .delete {
            let ingredient = fetchedResultsController.object(at: indexPath)
            ingredientController?.delete(ingredient: ingredient, context: CoreDataStack.shared.mainContext)
        }  
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ingredient = fetchedResultsController.object(at: indexPath)
        choose(ingredient: ingredient)
    }
    
    //MARK: Private
    
    private func choose(ingredient: Ingredient) {
        for callback in callbacks {
            callback(ingredient)
        }
    }
    
    private func frcPredicate(searchString: String? = nil) -> NSPredicate? {
        guard let game = gameReference?.game else { return nil }
        
        var predicates: [NSPredicate] = [NSPredicate(format: "ANY games == %@", game)]
        
        if let searchString = searchString?.lowercased(),
            !searchString.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[c] %@", searchString))
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    //MARK: Public
    
    func askForQuantity(completion: @escaping (Int16?) -> Void ) {
        let alertController = UIAlertController(title: "How many?", message: nil, preferredStyle: .alert)
        
        let add = UIAlertAction(title: "Add", style: .default) { _ in
            guard let quantityText = alertController.textFields?[0].text,
                let quantity = Int16(quantityText) else {
                completion(0)
                return
            }
            
            completion(quantity)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(nil)
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Quantity (optional)"
            textField.keyboardType = .numberPad
            textField.returnKeyType = .done
        }
        
        alertController.addAction(add)
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: Actions
    
    @IBAction func addIngredient(_ sender: UIBarButtonItem) {
        guard let game = gameReference?.game else { return }
        
        let alertController = UIAlertController(title: "New Ingredient", message: nil, preferredStyle: .alert)
        
        let save = UIAlertAction(title: "Save", style: .default) { _ in
            guard let name = alertController.textFields?[0].text else { return }
            
            let id: String? = alertController.textFields?[1].text
            
            self.ingredientController?.create(ingredient: name, game: game, id: id, context: CoreDataStack.shared.mainContext)
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Ingredient name"
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Form ID (optional)"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
        }
                
        alertController.addAction(save)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}

//MARK: Fetched Results Controller Delegate

extension IngredientsTableViewController: NSFetchedResultsControllerDelegate {
    
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

//MARK: Search results updating

extension IngredientsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text,
            let predicate = frcPredicate(searchString: searchString) else { return }
        
        fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            NSLog("Error performing fetch for module FRC: \(error)")
        }
    }
}
