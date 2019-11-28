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
    let moduleController = ModuleController()
    var characterController: CharacterController?
    
    var attributeTypeSectionController: AttributeTypeSectionController? {
        didSet {
            guard let game = gameReference?.game else { return }
            attributeTypeSectionController?.loadTempSections(for: game)
        }
    }
    
    var character: Character? {
        didSet {
            guard let character = character else { return }
            race = character.race
            female = character.female
            attributeController.fetchTempAttributes(for: character, context: CoreDataStack.shared.mainContext)
            moduleController.fetchTempModules(for: character, context: CoreDataStack.shared.mainContext)
            attributeTypeSectionController?.loadTempSections(for: character)
        }
    }
    
    var attributeTypeController: AttributeTypeController?
    var gameReference: GameReference?
    var race: Race?
    var female: Bool = false
    var femaleSegmentedControl: UISegmentedControl?
    var textField: UITextField?

    var allSections: [String?] {
        var sections: [String?] = []
        
        sections.append("Character")
        
        for section in attributeTypeSectionController?.tempSectionsToShow ?? [] {
            sections.append(section.section.name)
            
            if section.section is ModuleType {
                sections.append(nil)
            }
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
        
        guard let tempSection = attributeTypeSectionController?.sectionToShow(section) else {
            // Character section or module options section
            return 2
        }
        
        if tempSection.collapsed {
            return 0
        }
        
        if let tempAttributes = attributeController.getTempAttributes(from: tempSection.section) {
            return tempAttributes.count + 1
        } else if let tempModules = moduleController.getTempModules(from: tempSection.section) {
            return tempModules.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return allSections[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if attributeTypeSectionController?.sectionToShow(section - 1)?.section is ModuleType {
            return 2
        }
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        view.tag = section
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleSection(_:)))
        view.addGestureRecognizer(tap)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let tempSection = attributeTypeSectionController?.sectionToShow(section),
            let section = tempSection.section as? ModuleType {
            if let tempModules = moduleController.getTempModules(from: section),
                tempModules.count == 0
                    || tempSection.collapsed {
                return 2
            }
        }
        
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if let section = attributeTypeSectionController?.sectionToShow(indexPath.section) {
            if let attributeSection = section.section as? AttributeTypeSection,
                let tempAttributes = attributeController.getTempAttributes(from: attributeSection) {
                if indexPath.row < tempAttributes.count {
                    cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath)
                    cell.textLabel?.text = tempAttributes[indexPath.row].name
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "SelectAttributeCell", for: indexPath)
                    cell.textLabel?.text = "Add \(attributeSection.typeName)s"
                }
            } else if let moduleSection = section.section as? ModuleType,
                let tempModules = moduleController.getTempModules(from: moduleSection) {
                cell = tableView.dequeueReusableCell(withIdentifier: "ModuleDetailCell", for: indexPath)
                let module = tempModules[indexPath.row]
                cell.textLabel?.text = module.name
                
                if module.level > 0 {
                    cell.detailTextLabel?.text = "Level \(module.level)"
                } else {
                    cell.detailTextLabel?.text = nil
                }
                
                if moduleController.tempModules[module] ?? false {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .disclosureIndicator
                }
            } else {
                // This shouldn't happen and is just a fallback in case something breaks
                cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath)
            }
        } else if let moduleSection = attributeTypeSectionController?.sectionToShow(indexPath.section - 1)?.section as? ModuleType {
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectModuleCell", for: indexPath)
                cell.textLabel?.text = "Add \(moduleSection.typeName)s"
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "ViewIngredientsCell", for: indexPath)
            }
        } else {
            // Character section
            if indexPath.row == 0 {
                if let textFieldCell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as? CharacterNameTableViewCell {
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
                if let race = race,
                    race.managedObjectContext != nil {
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
            if let tempAttributes = attributeController.getTempAttributes(from: section.section) {
                if indexPath.row < tempAttributes.count {
                    // Attribute
                    return true
                } else {
                    // "Add attribute" cell
                    return false
                }
            } else if let tempModules = moduleController.getTempModules(from: section.section) {
                if indexPath.row < tempModules.count {
                    // Module
                    return true
                } else {
                    // "Add module" cell
                    return false
                }
            } else {
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
                if let tempAttributes = attributeController.getTempAttributes(from: section.section),
                    indexPath.row < tempAttributes.count {
                    attributeController.remove(tempAttribute: tempAttributes[indexPath.row])
                } else if let tempModules = moduleController.getTempModules(from: section.section),
                    indexPath.row < tempModules.count {
                    moduleController.remove(tempModule: tempModules[indexPath.row])
                } else {
                    return
                }
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            characterHasBeenModified()
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
    
    @objc private func toggleSection(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        
        attributeTypeSectionController?.toggleSection(index)
        tableView.reloadSections([index], with: .automatic)
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
        
        let context = CoreDataStack.shared.mainContext
        let savedCharacter: Character
        
        if let character = character {
            characterController?.edit(character: character, name: name, race: race, female: female, context: context)
            savedCharacter = character
        } else {
            guard let character = characterController?.create(character: name, race: race, female: female, game: game, context: context) else { return }
            savedCharacter = character
        }
        
        attributeController.removeMissingTempAttributes(from: savedCharacter, context: context)
        attributeController.saveTempAttributes(to: savedCharacter, context: context)
        
        moduleController.removeMissingTempModules(from: savedCharacter, context: context)
        moduleController.saveTempModules(to: savedCharacter, context: context)
        
        attributeTypeSectionController?.saveTempSections(to: savedCharacter)
        
        gameReference?.isSafeToChangeGame = true
    }
    
    private func characterHasBeenModified() {
        gameReference?.isSafeToChangeGame = false
        saveButton.isEnabled = true
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
                    self.characterHasBeenModified()
                    self.navigationController?.popViewController(animated: true)
                }
            } else if let indexPath = tableView.indexPathForSelectedRow {
                if let section = attributeTypeSectionController?.sectionToShow(indexPath.section) {
                    if let attributesVC = vc as? AttributesTableViewController {
                        guard let attributesSection = section.section as? AttributeTypeSection,
                            let selectedAttributes = attributeController.getTempAttributes(from: section.section) else { return }
                        
                        attributesVC.checkedAttributes = selectedAttributes
                        
                        attributesVC.attributeController = attributeController
                        attributesVC.attributeType = attributesSection.type
                        
                        attributesVC.callbacks.append { attribute in
                            self.attributeController.toggle(tempAttribute: attribute, priority: attributesSection.minPriority)
                            self.characterHasBeenModified()
                        }
                    } else if let modulesSection = section.section as? ModuleType,
                        let selectedModules = moduleController.getTempModules(from: section.section) {
                        
                        if let moduleDetailVC = vc as? ModuleDetailTableViewController {
                            let module = selectedModules[indexPath.row]
                            moduleDetailVC.module = module
                            
                            if let character = character {
                                let characterModule = moduleController.fetchCharacterModule(for: character, module: module, context: CoreDataStack.shared.mainContext)
                                moduleDetailVC.characterModule = characterModule
                            }
                            
                            moduleDetailVC.moduleController = moduleController
                            moduleDetailVC.moduleType = modulesSection
                        }
                        
                    }
                } else if let section = attributeTypeSectionController?.sectionToShow(indexPath.section - 1),
                    let modulesSection = section.section as? ModuleType {
                    if let modulesVC = vc as? ModulesTableViewController,
                        let selectedModules = moduleController.getTempModules(from: section.section) {
                        
                        modulesVC.checkedModules = selectedModules
                        
                        modulesVC.moduleController = moduleController
                        modulesVC.moduleType = modulesSection
                        
                        modulesVC.callbacks.append { module in
                            self.moduleController.toggle(tempModule: module)
                            self.characterHasBeenModified()
                        }
                    } else if let characterIngredientsVC = vc as? CharacterIngredientsTableViewController {
                        characterIngredientsVC.moduleType = modulesSection
                        characterIngredientsVC.moduleController = moduleController
                    }
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

//MARK: Character name cell delegate

extension CharacterDetailTableViewController: CharacterNameCellDelegate {
    func valueChanged(_ sender: UISegmentedControl) {
        characterHasBeenModified()
        female = sender.selectedSegmentIndex == 0 ? false : true
    }
}

//MARK: Sections table delegate

extension CharacterDetailTableViewController: SectionsTableDelegate {
    func updateSections() {
        tableView.reloadData()
        characterHasBeenModified()
    }
}
