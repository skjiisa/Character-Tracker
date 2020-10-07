//
//  ModulesTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData

class ModulesTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var addModuleView: UIView!
    @IBOutlet weak var addModuleButton: UIButton!
    
    //MARK: Properties
    
    var moduleController: ModuleController?
    var moduleType: ModuleType?
    var checkedModules: [Module]?
    var excludedModule: Module?
    var character: Character?
    var gameReference: GameReference?
    var showAll = false
    var callbacks: [( (Module) -> Void )] = []

    let searchController = UISearchController(searchResultsController: nil)
    var filteredTypes = Set<ModuleType>()
    var filteredAttributes = Set<Attribute>()
    public var requireAllAttributes: Bool = true {
        didSet {
            filter()
        }
    }
    
    var typeName: String {
        if let name = moduleType?.name {
            return name
        } else {
            return "Module"
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Module>? = {
        let fetchRequest: NSFetchRequest<Module> = Module.fetchRequest()
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        fetchRequest.predicate = frcPredicate()
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: CoreDataStack.shared.mainContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            fatalError("Error performing fetch for module FRC: \(error)")
        }
        
        return frc
    }()
    
    //MARK: View loading

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = typeName.pluralize()
        addModuleButton.setTitle("Add \(typeName)", for: .normal)
        
        if moduleType == nil || showAll {
            addModuleView.isHidden = true
        }
        
        if showAll {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        }
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        var rightBarButtonItems: [UIBarButtonItem] = []
        
        // Add filter button only if there are parameters to filter
        
        if moduleType == nil || fetchedResultsController?.fetchedObjects?.first(where: { $0.attributes?.anyObject() != nil }) != nil {
            let filterButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(showFilter))
            rightBarButtonItems.append(filterButton)
        }
        
        // Add QR Code scanner button
        
        let qrScannerButton = UIBarButtonItem(image: UIImage(systemName: "qrcode.viewfinder"), style: .plain, target: self, action: #selector(openScanner))
        rightBarButtonItems.append(qrScannerButton)
        
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    @objc private func showFilter() {
        let modulesFilterForm = UIHostingController(rootView:
            NavigationView {
                ModulesFilterForm(type: moduleType,
                                  checkedTypes: filteredTypes,
                                  checkedAttributes: filteredAttributes,
                                  delegate: self)
                    .environment(\.managedObjectContext, CoreDataStack.shared.mainContext)
            }.navigationViewStyle(StackNavigationViewStyle())
        )
        present(modulesFilterForm, animated: true)
    }

    //MARK: Table view data source
    
    func loadCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let module = fetchedResultsController?.object(at: indexPath) else { return }
        
        cell.textLabel?.text = module.name
        
        if showAll,
            let gameNames = module.games?.compactMap({ ($0 as? Game)?.name }) {
            cell.detailTextLabel?.text = gameNames.joined(separator: ", ")
        } else {
            let attributes = module.attributes?.sortedArray(using: [NSSortDescriptor(key: "attribute.name", ascending: true)]) as? [ModuleAttribute]
            let attiributeNames = attributes?.compactMap({ $0.attribute?.name })
            cell.detailTextLabel?.text = attiributeNames?.joined(separator: ", ")
        }
        
        if checkedModules?.contains(module) ?? false {
            cell.accessoryType = .checkmark
            cell.tintColor = .systemBlue
        } else if let characterModules = module.characters as? Set<CharacterModule>,
            !characterModules.isEmpty,
            // We don't want a green or grey checkmark if the selected character is the only one with this module
            characterModules.count > 1 || !characterModules.contains(where: { $0.character == character }) {
            cell.accessoryType = .checkmark
            
            // Grey if a different character has this module but not completed
            // Green if a different character has this module completed
            // Prominant colors if this is the general list (like in Settings)
            // Faded colors if this is selecting modules for a character
            if characterModules.contains(where: { $0.completed }) {
                if checkedModules == nil {
                    cell.tintColor = .systemGreen
                } else {
                    cell.tintColor = UIColor(red: 0.00, green: 0.80, blue: 0.28, alpha: 0.25)
                }
            } else {
                if checkedModules == nil {
                    cell.tintColor = .systemGray
                } else {
                    cell.tintColor = .systemGray4
                }
            }
        } else {
            cell.accessoryType = .none
            cell.tintColor = .systemBlue
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String
        
        if checkedModules == nil,
            !showAll {
            cellIdentifier = "ModuleDetailCell"
        } else {
            cellIdentifier = "ModuleCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        loadCell(cell, at: indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let module = fetchedResultsController?.object(at: indexPath) else { return }
            
            if module.games?.count ?? 0 > 1, // If this module is tied to other games
                !showAll { // and you aren't on the master list
                guard let game = gameReference?.game else { return }
                moduleController?.remove(game: game, from: module, context: CoreDataStack.shared.mainContext)
            } else {
                moduleController?.delete(module, context: CoreDataStack.shared.mainContext)
            }
        }
    }
    
    //MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let module = fetchedResultsController?.object(at: indexPath) else { return }
        choose(module: module)
        
        if !showAll,
            checkedModules != nil,
            let cell = tableView.cellForRow(at: indexPath) {

            if let index = checkedModules?.firstIndex(of: module) {
                checkedModules?.remove(at: index)
                loadCell(cell, at: indexPath)
            } else {
                checkedModules?.append(module)
                loadCell(cell, at: indexPath)
            }
        }
    }
    
    //MARK: Private
    
    private func choose(module: Module) {
        for callback in callbacks {
            callback(module)
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
            
            if let type = moduleType {
                predicates.append(NSPredicate(format: "type == %@", type))
            }
            
            if let excludedModuleUUID = excludedModule?.id {
                predicates.append(NSPredicate(format: "id != %@", excludedModuleUUID as CVarArg))
            }
        } else if let gameModules = game.modules {
            predicates.append(NSPredicate(format: "NOT (SELF in %@)", gameModules))
            
            if let type = moduleType {
                predicates.append(NSPredicate(format: "type == %@", type))
            }
        }
        
        if let searchString = searchString?.lowercased(),
            !searchString.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[c] %@", searchString))
        }
        
        if !filteredAttributes.isEmpty {
            if requireAllAttributes {
                predicates.append(NSPredicate(format: "SUBQUERY(attributes, $moduleAttribute, $moduleAttribute.attribute in %@).@count = %d", filteredAttributes, filteredAttributes.count))
            } else {
                predicates.append(NSPredicate(format: "ANY attributes.attribute in %@", filteredAttributes))
            }
        }
        
        if !filteredTypes.isEmpty {
            predicates.append(NSPredicate(format: "type in %@", filteredTypes))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    //MARK: Scanner
    
    @objc func openScanner() {
        let scannerVC = ScannerViewController()
        scannerVC.title = "Import from QR Code"
        scannerVC.delegate = self
        let scannerNavigationView = UINavigationController(rootViewController: scannerVC)
        present(scannerNavigationView, animated: true)
    }

    //MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination: UIViewController
        
        if let navigationVC = segue.destination as? UINavigationController,
            let firstVC = navigationVC.viewControllers.first {
            destination = firstVC
        } else {
            destination = segue.destination
        }
        
        if let vc = destination as? CharacterTrackerViewController {
            vc.gameReference = gameReference
            
            if let moduleDetailVC = vc as? ModuleDetailTableViewController {
                moduleDetailVC.moduleType = moduleType
                
                switch segue.identifier {
                case "ShowModuleDetail":
                    if let indexPath = tableView.indexPathForSelectedRow {
                        moduleDetailVC.module = fetchedResultsController?.object(at: indexPath)
                    }
                case "NewModule":
                    moduleDetailVC.editMode = true
                default:
                    break
                }
            }
        }
    }
    
    private func presentAllModules() {
        guard let modulesVC = storyboard?.instantiateViewController(withIdentifier: "ModulesTable") as? ModulesTableViewController else { return }
        let navigationVC = UINavigationController(rootViewController: modulesVC)
        
        modulesVC.gameReference = gameReference
        modulesVC.showAll = true
        modulesVC.moduleController = moduleController
        modulesVC.moduleType = moduleType
        modulesVC.callbacks.append { module in
            guard let game = self.gameReference?.game else { return }
            self.moduleController?.add(game: game, to: module, context: CoreDataStack.shared.mainContext)
            self.dismiss(animated: true, completion: nil)
        }
        
        present(navigationVC, animated: true)
    }

    //MARK: Actions
    
    @IBAction func addModule(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add \(typeName)", message: nil, preferredStyle: .actionSheet)
        
        let addExisting = UIAlertAction(title: "Add \(typeName) from other game", style: .default) { _ in
            DispatchQueue.main.async {
                self.presentAllModules()
            }
        }
        
        let addNew = UIAlertAction(title: "Add new \(typeName)", style: .default) { _ in
            self.performSegue(withIdentifier: "NewModule", sender: self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addNew)
        alertController.addAction(addExisting)
        alertController.addAction(cancelAction)
        
        alertController.pruneNegativeWidthConstraints()
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            let buttonBounds = addModuleButton.convert(addModuleButton.bounds, to: self.view)
            popoverController.sourceRect = buttonBounds
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }

}

//MARK: Search results updating

extension ModulesTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filter()
    }
}

//MARK: Modules filter form delegate

extension ModulesTableViewController: ModulesFilterFormDelegate {
    func toggle(_ moduleType: ModuleType) {
        filteredTypes.formSymmetricDifference([moduleType])
        filter()
    }
    
    func toggle(_ attribute: Attribute) {
        filteredAttributes.formSymmetricDifference([attribute])
        filter()
    }
    
    func clearFilter() {
        filteredAttributes.removeAll()
        filteredTypes.removeAll()
        filter()
    }
    
    func dismiss() {
        dismiss(animated: true)
    }
}
