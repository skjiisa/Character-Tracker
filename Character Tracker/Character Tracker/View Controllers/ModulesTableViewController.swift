//
//  ModulesTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/11/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
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
    var gameReference: GameReference?
    var showAll = false
    var callbacks: [( (Module) -> Void )] = []
    
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
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = typeName.pluralize()
        addModuleButton.setTitle("Add \(typeName)", for: .normal)
        
        if showAll {
            addModuleView.isHidden = true
        }
    }

    //MARK: Table view data source

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

        guard let module = fetchedResultsController?.object(at: indexPath) else {
            return cell
        }
        
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
        }

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
                moduleController?.delete(module: module, context: CoreDataStack.shared.mainContext)
            }
        }
    }
    
    //MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let module = fetchedResultsController?.object(at: indexPath) else { return }
        choose(module: module)
        
        if !showAll,
            checkedModules != nil {
            
            if let cell = tableView.cellForRow(at: indexPath) {
                if cell.accessoryType == .none {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
        }
    }
    
    //MARK: Private
    
    func choose(module: Module) {
        for callback in callbacks {
            callback(module)
        }
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
            
            if let modulesVC = vc as? ModulesTableViewController {
                modulesVC.showAll = true
                modulesVC.moduleController = moduleController
                modulesVC.moduleType = moduleType
                modulesVC.callbacks.append { module in
                    guard let game = self.gameReference?.game else { return }
                    self.moduleController?.add(game: game, to: module, context: CoreDataStack.shared.mainContext)
                    self.dismiss(animated: true, completion: nil)
                }
            } else if let moduleDetailVC = vc as? ModuleDetailTableViewController {
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

    //MARK: Actions
    
    @IBAction func addModule(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add \(typeName)", message: nil, preferredStyle: .actionSheet)
        
        let addExisting = UIAlertAction(title: "Add existing \(typeName)", style: .default) { _ in
            self.performSegue(withIdentifier: "ModalShowModules", sender: self)
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
    
}

//MARK: Fetched results controller delegate

extension ModulesTableViewController: NSFetchedResultsControllerDelegate {
    
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
