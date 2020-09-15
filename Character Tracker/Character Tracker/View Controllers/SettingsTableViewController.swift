//
//  SettingsTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/1/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import SwiftUI

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
    
    let links: [(title: String, urlString: String)] = [
        ("Support Website", "https://github.com/Isvvc/Character-Tracker/issues"),
        ("Email Support", "mailto:lyons@tuta.io"),
        ("Privacy Policy", "https://github.com/Isvvc/Character-Tracker/blob/master/Privacy%20Policy.txt"),
        ("Source Code", "https://github.com/Isvvc/Character-Tracker")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Game"
        case 3:
            return "Attributes"
        case 4:
            return "Modules"
        case 5:
            return "Preferences"
        case 6:
            return "App Information"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 3 {
            return "Attributes are simple tags"
        } else if section == 4 {
            return "Modules hold information about level, requirements, etc."
        }
        
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0..<3, 5:
            return 1
        case 3:
            return attributeTypeController?.types.count ?? 0
        case 4:
            return moduleTypeController?.types.count ?? 0
        default:
            return links.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectGameCell", for: indexPath)
            cell.textLabel?.text = gameReference?.name
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectRaceCell", for: indexPath)
            cell.textLabel?.text = "Races"
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "DefaultSectionsCell", for: indexPath)
        case 3:
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectAttributeCell", for: indexPath)
            if let attributeTypeName = attributeTypeController?.types[indexPath.row].name?.capitalized {
                cell.textLabel?.text = "\(attributeTypeName.pluralize())"
            }
        case 4:
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectModuleCell", for: indexPath)
            if let moduleTypeName = moduleTypeController?.types[indexPath.row].name {
                cell.textLabel?.text = moduleTypeName.pluralize()
            }
        case 5:
            cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
            cell.textLabel?.text = "User Preferences"
            cell.accessoryType = .disclosureIndicator
        default:
            guard let linkCell = tableView.dequeueReusableCell(withIdentifier: "LinkCell", for: indexPath) as? LinkTableViewCell else { return UITableViewCell() }
            let link = links[indexPath.row]
            
            linkCell.button.setTitle(link.title, for: .normal)
            linkCell.url = URL(string: link.urlString)
            cell = linkCell
        }

        return cell
    }
    
    //MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 5:
            let preferencesForm = UIHostingController(rootView: PreferencesForm())
            preferencesForm.title = "Preferences"
            navigationController?.pushViewController(preferencesForm, animated: true)
        case 6:
            guard let cell = tableView.cellForRow(at: indexPath) as? LinkTableViewCell else { break }
            cell.openLink(self)
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }

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
