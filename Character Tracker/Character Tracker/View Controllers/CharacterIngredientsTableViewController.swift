//
//  CharacterIngredientsTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/26/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit
import CoreData

class CharacterIngredientsTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var accumulateButton: UIButton!
    
    //MARK: Properties
    
    var gameReference: GameReference?
    var moduleController: ModuleController? {
        didSet {
            setModules()
        }
    }
    var moduleType: ModuleType?
    var character: Character?
    
    var modules: [Module] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    //MARK: Private
    
    private func setModules() {
        let uncheckedTempModules = moduleController?.tempEntities.filter({ $0.value == false && $0.entity.type == moduleType }) ?? []
        let uncheckedModules = uncheckedTempModules.map({ $0.entity })
        
        modules = uncheckedModules.sorted(by: { module1, module2 -> Bool in
            // Modules with no level will be sorted to the end of the list
            // Modules with no level are stored as level 0
            // In order to sort level 0 modules to the end of the list, modules with level 0 are tested as if they are 1 level higher than the other module
            // If both modules are the same level (including if they're both 0), they will be sorted by name
            
            let module1Level: Int16
            
            if module1.level == 0 {
                module1Level = module2.level + 1
            } else {
                module1Level = module1.level
            }
            
            let module2Level: Int16
            
            if module2.level == 0 {
                module2Level = module1.level + 1
            } else {
                module2Level = module2.level
            }
            
            if module1Level > module2Level {
                return false
            } else if module2Level > module1Level {
                return true
            }
            
            if let module1Name = module1.name,
                let module2Name = module2.name {
                return module1Name < module2Name
            }
            
            return true
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return modules.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let module = modules[section]
        let moduleName = module.name ?? ""
        let level = module.level
        
        let title: String
        
        if level == 0 {
            title = "Unleveled: \(moduleName)"
        } else {
            title = "Level \(module.level): \(moduleName)"
        }
        
        return title
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modules[section].ingredients?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)

        let module = modules[indexPath.section]
        guard let moduleIngredient = moduleController?.getModuleIngredient(module: module, forRowAt: indexPath) else { return cell }
        
        cell.textLabel?.text = moduleIngredient.ingredient?.name
        
        var quantity = moduleIngredient.quantity
        
        if accumulateButton.isSelected,
            module.level != 0 {
            for i in 0..<indexPath.section {
                let lowerLevelModule = modules[i]
                guard lowerLevelModule.level < module.level else { break }
                
                for lowerLevelModuleIngredient in lowerLevelModule.mutableSetValue(forKey: "ingredients") {
                    guard let lowerLevelModuleIngredient = lowerLevelModuleIngredient as? ModuleIngredient else { continue }
                    
                    if lowerLevelModuleIngredient.ingredient == moduleIngredient.ingredient {
                        quantity += lowerLevelModuleIngredient.quantity
                        break
                    }
                }
            }
        }
        
        if quantity > 0 {
            cell.detailTextLabel?.text = "Qty: \(quantity)"
        } else {
            cell.detailTextLabel?.text = nil
        }
        
        if let character = character,
            moduleIngredient.characters?.contains(character) ?? false {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let module = modules[indexPath.section]
        guard let cell = tableView.cellForRow(at: indexPath),
            let character = character else { return }
        
        if moduleController?.toggle(character: character,
                                    ingredientAtIndexPath: indexPath,
                                    inModule: module,
                                    context: CoreDataStack.shared.mainContext) ?? false {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }

    //MARK: Actions
    
    @IBAction func toggleAccumulate(_ sender: UIButton) {
        sender.isSelected.toggle()
        tableView.reloadData()
    }
    
}
