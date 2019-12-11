//
//  SettingsTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, CharacterTrackerViewController {
    
    var attributeController = AttributeController()
    var attributeTypeSectionController = AttributeTypeSectionController()
    var moduleController = ModuleController()
    var attributeTypeController: AttributeTypeController?
    var moduleTypeController: ModuleTypeController?
    var gameReference: GameReference? {
        didSet {
            gameReference?.callbacks.append {
                self.tableView.reloadData()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Game"
        } else if section == 1 {
            //return "\(gameReference?.name ?? "") Settings"
        } else if section == 3 {
            return "Attributes"
        } else if section == 4 {
            return "Modules"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 3 {
            //return "Character Attributes"
            return "Attributes are simple tags that characters can have"
        } else if section == 4 {
            //return "Modules"
            return "Modules hold information about level, requirements, etc."
        }
        
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < 3 {
            return 1
        } else if section == 3 {
            return attributeTypeController?.types.count ?? 0
        } else {
            return moduleTypeController?.types.count ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectGameCell", for: indexPath)
            cell.textLabel?.text = gameReference?.name
        } else if indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectRaceCell", for: indexPath)
            cell.textLabel?.text = "Races"
        } else if indexPath.section == 2 {
            cell = tableView.dequeueReusableCell(withIdentifier: "DefaultSectionsCell", for: indexPath)
        } else if indexPath.section == 3 {
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectAttributeCell", for: indexPath)
            if let attributeTypeName = attributeTypeController?.types[indexPath.row].name?.capitalized {
                cell.textLabel?.text = "\(attributeTypeName)s"
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectModuleCell", for: indexPath)
            if let moduleTypeName = moduleTypeController?.types[indexPath.row].name {
                if moduleTypeName != "Equipment" {
                    cell.textLabel?.text = "\(moduleTypeName)s"
                } else {
                    cell.textLabel?.text = moduleTypeName
                }
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CharacterTrackerViewController {
            vc.gameReference = gameReference
            
            if let gamesTableVC = segue.destination as? GamesTableViewController {
                gamesTableVC.gameReference = self.gameReference
            } else if let racesVC = vc as? RacesTableViewController {
                racesVC.tableView.allowsSelection = false
            } else if let indexPath = tableView.indexPathForSelectedRow {
                
                if let attributesVC = vc as? AttributesTableViewController {
                    attributesVC.attributeController = attributeController
                    attributesVC.attributeType = attributeTypeController?.types[indexPath.row]
                    attributesVC.tableView.allowsSelection = false
                } else if let modulesVC = vc as? ModulesTableViewController {
                    modulesVC.moduleController = moduleController
                    modulesVC.moduleType = moduleTypeController?.types[indexPath.row]
                }
                
            }
        } else if let sectionsVC = segue.destination as? SectionsTableViewController {
            guard let game = gameReference?.game else { return }
            attributeTypeSectionController.loadTempSections(for: game)
            sectionsVC.attributeTypeSectionController = attributeTypeSectionController
            sectionsVC.delegate = self
            sectionsVC.navigationItem.rightBarButtonItem = nil
        }
    }

}

extension SettingsTableViewController: SectionsTableDelegate {
    func updateSections() {
        guard let game = gameReference?.game else { return }
        attributeTypeSectionController.saveTempSections(to: game)
    }
}
