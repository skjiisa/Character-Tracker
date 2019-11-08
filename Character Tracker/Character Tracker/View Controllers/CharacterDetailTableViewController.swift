//
//  CharacterDetailTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/30/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

class CharacterDetailTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    //MARK: Properties
    
    let attributeController = AttributeController()
    let characterController = CharacterController()
    
    var character: Character? {
        didSet {
            guard let character = character else { return }
            race = character.race
            female = character.female
            attributeController.fetchAttributes(for: character, context: CoreDataStack.shared.mainContext)
        }
    }
    
    var attributeTypeController: AttributeTypeController?
    var attributeTypeSectionController: AttributeTypeSectionController?
    var gameReference: GameReference?
    var race: Race?
    var female: Bool = false
    var femaleSegmentedControl: UISegmentedControl?
    var textField: UITextField?

    var allSections: [String] {
        var sections: [String] = []
        
        sections.append("Character")
        
        for section in attributeTypeSectionController?.tempSectionsToShow ?? [] {
            sections.append(section.name ?? "")
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
        saveButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return allSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let section = attributeTypeSectionController?.sectionToShow(section) else {
            // Character section
            return 2
        }
        
        guard let tempAttributes = attributeController.getTempAttributes(from: section) else { return 0 }
        
        return tempAttributes.count + 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return allSections[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if let section = attributeTypeSectionController?.sectionToShow(indexPath.section) {
            guard let tempAttributes = attributeController.getTempAttributes(from: section) else { return UITableViewCell() }
            
            if indexPath.row < tempAttributes.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath)
                cell.textLabel?.text = tempAttributes[indexPath.row].name
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectAttributeCell", for: indexPath)
                if let typeName = section.type?.name {
                    cell.textLabel?.text = "Add \(typeName)s"
                }
            }
        } else {
            // Character section
            if indexPath.row == 0 {
                if let textFieldCell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as? TextFieldTableViewCell {
                    textField = textFieldCell.textField
                    textField?.delegate = self

                    if let name = textField?.text,
                        name == "",
                        let character = character {
                        textField?.text = character.name
                    }
                    
                    femaleSegmentedControl = textFieldCell.femaleSegmentedControl
                    textFieldCell.delegate = self
                    
                    femaleSegmentedControl?.selectedSegmentIndex = female ? 1 : 0
                    
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

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if let section = attributeTypeSectionController?.sectionToShow(indexPath.section) {
            guard let tempAttributes = attributeController.getTempAttributes(from: section) else { return false }
            
            if indexPath.row < tempAttributes.count {
                // Attribute
                return true
            } else {
                // "Add attribute" cell
                return false
            }
        } else {
            // Character section
            return false
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            if let section = attributeTypeSectionController?.sectionToShow(indexPath.section) {
                guard let tempAttributes = attributeController.getTempAttributes(from: section) else { return }
                
                if indexPath.row < tempAttributes.count {
                    attributeController.remove(tempAttribute: tempAttributes[indexPath.row])
                }
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
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
    
    //MARK: Private
    
    private func updateViews() {
        guard isViewLoaded else { return }
        
        if let character = character {
            title = character.name
        } else {
            title = "New Character"
        }
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
        
        guard let selectedSegmentIndex = femaleSegmentedControl?.selectedSegmentIndex else { return }
        let female: Bool = selectedSegmentIndex == 0 ? false : true
        
        let savedCharacter: Character
        
        if let character = character {
            characterController.edit(character: character, name: name, race: race, female: female, context: CoreDataStack.shared.mainContext)
            savedCharacter = character
        } else {
            savedCharacter = characterController.create(character: name, race: race, female: female, game: game, context: CoreDataStack.shared.mainContext)
        }
        
        attributeController.removeMissingTempAttributes(from: savedCharacter, context: CoreDataStack.shared.mainContext)
        attributeController.saveTempAttributes(to: savedCharacter, context: CoreDataStack.shared.mainContext)
        
        gameReference?.isSafeToChangeGame = true
        navigationController?.popViewController(animated: true)
    }
    
    private func characterHasBeenModified() {
        gameReference?.isSafeToChangeGame = false
        saveButton.isEnabled = true
    }
    
    //MARK: Actions
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        save()
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
                    self.characterHasBeenModified()
                    self.navigationController?.popViewController(animated: true)
                }
            } else if let attributesVC = vc as? AttributesTableViewController,
                let indexPath = tableView.indexPathForSelectedRow {
                
                guard let section = attributeTypeSectionController?.sectionToShow(indexPath.section),
                    let selectedAttributes = attributeController.getTempAttributes(from: section) else { return }
                
                attributesVC.checkedAttributes = selectedAttributes
                
                attributesVC.attributeController = attributeController
                attributesVC.attributeType = section.type
                
                attributesVC.callbacks.append { attribute in
                    self.attributeController.add(tempAttribute: attribute, priority: section.minPriority)
                    self.characterHasBeenModified()
                }
            }
        } else if let sectionsVC = segue.destination as? SectionsTableViewController {
            sectionsVC.attributeTypeSectionController = attributeTypeSectionController
            sectionsVC.delegate = self
        }
    }

}

//MARK: Text field delegate

extension CharacterDetailTableViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != character?.name {
            characterHasBeenModified()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return false
    }
}

//MARK: Segmented control delegate

extension CharacterDetailTableViewController: SegmentedControlDelegate {
    func valueChanged(_ sender: UISegmentedControl) {
        characterHasBeenModified()
        female = sender.selectedSegmentIndex == 0 ? false : true
    }
}

//MARK: Sections table delegate

extension CharacterDetailTableViewController: SectionsTableDelegate {
    func updateSections() {
        tableView.reloadData()
    }
}
