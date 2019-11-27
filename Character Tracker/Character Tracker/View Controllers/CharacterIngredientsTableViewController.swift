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
    
    //MARK: Properties
    
    var gameReference: GameReference?
    var moduleController: ModuleController? {
        didSet {
            setModules()
        }
    }
    var moduleType: ModuleType?
    
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
        let uncheckedModulesDictionary = moduleController?.tempModules.filter({ $0.value == false && $0.key.type == moduleType }) ?? [:]
        let uncheckedModules = uncheckedModulesDictionary.map({ $0.key })
        
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
            } else if module2Level < module1Level {
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
        
        for moduleIngredient in module.mutableSetValue(forKey: "ingredients") {
            guard let moduleIngredient = moduleIngredient as? ModuleIngredient else { continue }
            
            cell.textLabel?.text = moduleIngredient.ingredient?.name
            
            let quantity = moduleIngredient.quantity
            if quantity > 0 {
                cell.detailTextLabel?.text = "Qty: \(quantity)"
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
