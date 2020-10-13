//
//  AttributesTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import SwiftUI
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
    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredTypes: Set<AttributeType>?
    
    var typeName: String {
        if let name = attributeType?.name {
            return name.capitalized
        } else {
            return "Attribute"
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Attribute>? = {
        
        let fetchRequest: NSFetchRequest<Attribute> = Attribute.fetchRequest()
        
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
            fatalError("Error performing fetch for game frc: \(error)")
        }
        
        return frc
    }()
    
    //MARK: View loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = typeName.pluralize()
        addAttributeButton.setTitle("Add \(typeName)", for: .normal)
        
        if attributeType == nil || showAll {
            addAttributeView.isHidden = true
        }
        
        if showAll {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        }
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Add filter button only if there is no type set
        
        if attributeType == nil {
            filteredTypes = Set<AttributeType>()
            
            let filterButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(showFilter))
            navigationItem.rightBarButtonItem = filterButton
        }
    }
    
    @objc private func showFilter() {
        let attributesFilterForm = UIHostingController(rootView:
            NavigationView {
                AttributesFilterForm(checkedTypes: filteredTypes,
                                     delegate: self)
                    .environment(\.managedObjectContext, CoreDataStack.shared.mainContext)
            }.navigationViewStyle(StackNavigationViewStyle())
        )
        present(attributesFilterForm, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath)
        
        guard let attribute = fetchedResultsController?.object(at: indexPath) else {
            return cell
        }
        
        cell.textLabel?.text = attribute.name
        
        if showAll {
            if let allGames = gamesFRC.fetchedObjects,
                let game = gameReference?.game {
                let games = allGames.filter({ ($0.attributes?.contains(attribute) ?? false) && $0 != game })
                let gameNames = games.compactMap({ $0.name })
                cell.detailTextLabel?.text = gameNames.joined(separator: ", ")
            }
        } else if attributeType == nil {
            cell.detailTextLabel?.text = attribute.type?.name?.capitalized
        } else {
            cell.detailTextLabel?.text = nil
        }
        
        if checkedAttributes.contains(attribute) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let attribute = fetchedResultsController?.object(at: indexPath) else { return }
            
            if attribute.games?.count ?? 0 > 1, // If this attribute is tied to other games
                !showAll { // and you aren't in the master list
                guard let game = gameReference?.game else { return }
                attributeController?.remove(game: game, from: attribute, context: CoreDataStack.shared.mainContext)
            } else {
                attributeController?.delete(attribute, context: CoreDataStack.shared.mainContext)
            }
        }
    }
    
    //MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let attribute = fetchedResultsController?.object(at: indexPath) else { return }
        
        choose(attribute: attribute)
        
        if !showAll {
            let cell = tableView.cellForRow(at: indexPath)
            
            if let index = checkedAttributes.firstIndex(of: attribute) {
                checkedAttributes.remove(at: index)
                cell?.accessoryType = .none
            } else {
                checkedAttributes.append(attribute)
                cell?.accessoryType = .checkmark
            }
        }
    }
    
    //MARK: Private
    
    private func choose(attribute: Attribute) {
        for callback in callbacks {
            callback(attribute)
        }
    }
    
    private func filter() {
        guard let searchString = searchController.searchBar.text,
            let predicate = frcPredicate(searchString: searchString) else { return }
        
        fetchedResultsController?.fetchRequest.predicate = predicate
        do {
            try fetchedResultsController?.performFetch()
            tableView.reloadData()
        } catch {
            NSLog("Error performing fetch for module FRC: \(error)")
        }
    }
    
    private func frcPredicate(searchString: String? = nil) -> NSPredicate? {
        guard let game = gameReference?.game else { return nil }
        
        var predicates: [NSPredicate] = []
        
        if !showAll {
            predicates.append(NSPredicate(format: "ANY games == %@", game))
            
            if let type = attributeType {
                predicates.append(NSPredicate(format: "type == %@", type))
            }
        } else {
            if let gameAttributes = game.attributes {
                predicates.append(NSPredicate(format: "NOT (SELF in %@)", gameAttributes))
                
                if let type = attributeType {
                    predicates.append(NSPredicate(format: "type == %@", type))
                }
            }
        }
        
        if let searchString = searchString?.lowercased(),
            !searchString.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[c] %@", searchString))
        }
        
        if let filteredTypes = filteredTypes,
            !filteredTypes.isEmpty {
            predicates.append(NSPredicate(format: "type in %@", filteredTypes))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    //MARK: Actions
    
    @IBAction func addAttribute(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add \(typeName)", message: nil, preferredStyle: .actionSheet)
        
        let addExisting = UIAlertAction(title: "Add \(typeName) from other game", style: .default) { _ in
            DispatchQueue.main.async {
                self.presentAllAttributes()
            }
        }
        
        let addNew = UIAlertAction(title: "Add new \(typeName)", style: .default) { _ in
            self.showNewAttributeAlert()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addNew)
        alertController.addAction(addExisting)
        alertController.addAction(cancelAction)
        
        alertController.pruneNegativeWidthConstraints()
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            let buttonBounds = addAttributeButton.convert(addAttributeButton.bounds, to: self.view)
            popoverController.sourceRect = buttonBounds
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showNewAttributeAlert() {
        guard let game = gameReference?.game,
            let type = attributeType else { return }
        
        let alertController = UIAlertController(title: "New \(typeName)", message: "", preferredStyle: .alert)
        
        let saveVanilla = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let name = alertController.textFields?[0].text else { return }
            
            self?.attributeController?.create(attribute: name, game: game, type: type, context: CoreDataStack.shared.mainContext )
            self?.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "\(self.typeName) name"
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
        }
                
        alertController.addAction(saveVanilla)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    private func presentAllAttributes() {
        guard let attributesVC  = storyboard?.instantiateViewController(withIdentifier: "AttributesTable") as? AttributesTableViewController else { return }
        let navigationVC = UINavigationController(rootViewController: attributesVC)
        
        attributesVC.showAll = true
        attributesVC.gameReference = gameReference
        attributesVC.attributeController = attributeController
        attributesVC.attributeType = attributeType
        attributesVC.callbacks.append { attribute in
            guard let game = self.gameReference?.game else { return }
            self.attributeController?.add(game: game, to: attribute, context: CoreDataStack.shared.mainContext)
            self.dismiss(animated: true, completion: nil)
        }
        
        present(navigationVC, animated: true)
    }
    
}

//MARK: Search results updating

extension AttributesTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filter()
    }
}

//MARK: Attributes filter form delegate

extension AttributesTableViewController: AttributesFilterFormDelegate {
    func toggle(_ attributeType: AttributeType) {
        filteredTypes?.formSymmetricDifference([attributeType])
        filter()
    }
    
    func clearFilter() {
        filteredTypes?.removeAll()
        filter()
    }
    
    func dismiss() {
        dismiss(animated: true)
    }
}
