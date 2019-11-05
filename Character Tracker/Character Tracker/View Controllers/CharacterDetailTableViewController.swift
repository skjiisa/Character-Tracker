//
//  CharacterDetailTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

class CharacterDetailTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Properties
    
    let attributeController = AttributeController()
    let characterController = CharacterController()
    
    var character: Character?
    
    var gameReference: GameReference?
    var race: Race?
    var textField: UITextField?
        
    var sectionsForAttributeType: [(type: AttributeTypeKeys, sections: [String])] = [
        (.skill, ["Primary Skills", "Major Skills", "Minor Skills"]),
        (.objective, ["High Priority", "Low Priority"]),
        (.combatStyle, ["Primary Combat Styles", "Secondary Combat Styles"]),
        (.armorType,["Armor Type"])
    ]
    var allSections: [String] {
        var sections: [String] = []
        
        sections.append("Character")
        
        for type in sectionsForAttributeType {
            sections.append(contentsOf: type.sections)
        }
        
        return sections
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        updateViews()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return allSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let currentSubsection = self.subsection(for: section) else {
            // Character section
            return 2
        }
        
        let tempAttributes = attributeController.getTempAttributes(ofType: currentSubsection.type, priority: currentSubsection.priority)
        
        return tempAttributes.count + 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return allSections[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if let currentSubsection = self.subsection(for: indexPath.section) {
            let tempAttributes = attributeController.getTempAttributes(ofType: currentSubsection.type, priority: currentSubsection.priority)
            
            if indexPath.row < tempAttributes.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath)
                cell.textLabel?.text = tempAttributes[indexPath.row].name
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectAttributeCell", for: indexPath)
                cell.textLabel?.text = "Add \(currentSubsection.type.rawValue)"
            }
        } else {
            // Character section
            if indexPath.row == 0 {
                if let textFieldCell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as? TextFieldTableViewCell {
                    textField = textFieldCell.textField
                    cell = textFieldCell
                } else {
                    cell = UITableViewCell()
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectRaceCell", for: indexPath)
                if let race = race {
                    cell.textLabel?.text = race.name
                } else {
                    cell.textLabel?.text = "Select Race"
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
    
    func subsection(for section: Int) -> (type: AttributeTypeKeys, priority: Int16)? {
        var i = 0
        
        if section == 0 {
            return nil
        }
        
        var attributeType: AttributeTypeKeys?
        var priority: Int16?
        
        for typeTuplet in sectionsForAttributeType {
            if section <= i + typeTuplet.sections.count {
                attributeType = typeTuplet.type
                priority = Int16(section - i - 1)
                break
            } else {
                i += typeTuplet.sections.count
            }
        }
        
        guard let unwrappedAttributeType = attributeType,
            let unwrappedPriority = priority else { return nil }
        
        return (unwrappedAttributeType, unwrappedPriority)
    }
    
    //MARK: Private
    
    private func updateViews() {
        guard isViewLoaded else { return }
        
        title = "New Character"
    }
    
    private func prompt(message: String) {
        let alertController = UIAlertController(title: "Could not save character", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func save() {
        guard let game = gameReference?.game else { return }
        
        guard let name = textField?.text,
            !name.isEmpty else {
                prompt(message: "Please enter a character name.")
                return
        }
        
        guard let race = race else {
            prompt(message: "Please select a race.")
            return
        }
        
        if let character = character {
            characterController.edit(character: character, name: name, race: race, game: game, context: CoreDataStack.shared.mainContext)
        } else {
            characterController.create(character: name, race: race, game: game, context: CoreDataStack.shared.mainContext)
        }
        
        //TODO: save attributes
    }
    
    //MARK: Actions
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        save()
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CharacterTrackerViewController {
            vc.gameReference = gameReference
            
            if let racesVC = vc as? RacesTableViewController {
                racesVC.callbacks.append { race in
                    self.race = race
                    self.tableView.reloadData()
                    self.navigationController?.popViewController(animated: true)
                }
            } else if let attributesVC = vc as? AttributesTableViewController,
                let indexPath = tableView.indexPathForSelectedRow {
                
                guard let currentSubsection = self.subsection(for: indexPath.section) else { return }
                
                attributesVC.attributeController = attributeController
                attributesVC.attributeType = attributeController.type(currentSubsection.type)
                attributesVC.callbacks.append { attribute in
                    self.attributeController.add(tempAttribute: attribute, priority: currentSubsection.priority)
                    self.tableView.reloadData()
                    self.navigationController?.popViewController(animated: true)
                    
                }
            }
        }
    }

}
