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
            name = character.name
            race = character.race
            female = character.female
            attributeController.fetchTempAttributes(for: character, context: CoreDataStack.shared.mainContext)
            moduleController.fetchTempModules(for: character, context: CoreDataStack.shared.mainContext)
            attributeTypeSectionController?.loadTempSections(for: character)
        }
    }
    
    var attributeTypeController: AttributeTypeController?
    var gameReference: GameReference?
    var name: String?
    var race: Race?
    var female: Bool = false
    var femaleSegmentedControl: UISegmentedControl?
    var textField: UITextField?
    var editMode: Bool = false
    var checkRace: Bool = false
    
    var cancelButton: UIBarButtonItem {
        let barButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        barButton.tag = 1
        return barButton
    }
    var editButton: UIBarButtonItem {
        let barButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        barButton.tag = 2
        return barButton
    }
    var saveButton: UIBarButtonItem {
        let barButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped(_:)))
        barButton.tag = 3
        return barButton
    }
    var cancelEditButton: UIBarButtonItem {
        let barButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(endEdit))
        barButton.tag = 4
        return barButton
    }

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
        
        if character == nil {
            navigationItem.leftBarButtonItem = cancelButton
            navigationItem.rightBarButtonItem = saveButton
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem = editButton
        }
        
        updateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let character = character {
            moduleController.checkTempModules(againstCharacter: character, context: CoreDataStack.shared.mainContext)
        }
        tableView.reloadData()
    }

    //MARK: Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return allSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        
        guard let tempSection = attributeTypeSectionController?.sectionToShow(section) else {
            // Module options section
            if let tempSection = attributeTypeSectionController?.sectionToShow(section - 1),
                tempSection.collapsed {
                return 0
            }
            
            return 1 + editMode.int
        }
        
        if tempSection.collapsed {
            return 0
        }
        
        if let tempAttributes = attributeController.getTempAttributes(from: tempSection.section) {
            return tempAttributes.count + editMode.int
        } else if let tempModules = moduleController.getTempModules(from: tempSection.section) {
            return tempModules.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < allSections.count else {
            NSLog("That weird crash happened again where index is out of range for titleForHeaderInSection.")
            return "<Something went wrong!>"
        }
        let title = allSections[section]
        
        // Triangles: ▼▶︎▲
        if let title = title,
            let tempSection = attributeTypeSectionController?.sectionToShow(section) {
            if tempSection.collapsed {
                return "▶︎\t\(title)"
            }
            
            return "▼\t\(title)"
        }
        
        return title
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
                    cell.textLabel?.text = "Add \(attributeSection.typeName.pluralize())"
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
                
                if moduleController.tempEntities.first(where: { $0.entity == module })?.value ?? false {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .disclosureIndicator
                }
            } else {
                // This shouldn't happen and is just a fallback in case something breaks
                cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath)
            }
        } else if let tempSection = attributeTypeSectionController?.sectionToShow(indexPath.section - 1),
            let moduleSection = tempSection.section as? ModuleType {
            if indexPath.row == editMode.int {
                cell = tableView.dequeueReusableCell(withIdentifier: "ViewIngredientsCell", for: indexPath)
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectModuleCell", for: indexPath)
                cell.textLabel?.text = "Add \(moduleSection.typeName.pluralize())"
            }
        } else {
            // Character section
            if indexPath.row == 0 {
                if let textFieldCell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as? CharacterNameTableViewCell {
                    textField = textFieldCell.textField
                    textField?.delegate = self
                    
                    textField?.text = name
                    
                    femaleSegmentedControl = textFieldCell.femaleSegmentedControl
                    textFieldCell.delegate = self
                    
                    femaleSegmentedControl?.selectedSegmentIndex = female.int
                    femaleSegmentedControl?.setEnabled(editMode, forSegmentAt: (!female).int)
                    
                    cell = textFieldCell
                } else {
                    cell = UITableViewCell()
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectRaceCell", for: indexPath)
                if let race = race,
                    race.managedObjectContext != nil {
                    cell.textLabel?.text = race.name
                    checkRace = false
                } else {
                    cell.textLabel?.text = "Select Race"
                }
                
                if checkRace {
                    cell.textLabel?.textColor = UIColor.systemRed
                } else {
                    cell.textLabel?.textColor = UIColor.label
                }
                
                if editMode {
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.accessoryType = .none
                }
            }
        }
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if editMode,
            let section = attributeTypeSectionController?.sectionToShow(indexPath.section) {
            if let tempAttributes = attributeController.getTempAttributes(from: section.section) {
                return indexPath.row < tempAttributes.count
            } else if let tempModules = moduleController.getTempModules(from: section.section) {
                return indexPath.row < tempModules.count
            }
        }
        
        return false
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            if let section = attributeTypeSectionController?.sectionToShow(indexPath.section) {
                if let tempAttributes = attributeController.getTempAttributes(from: section.section),
                    indexPath.row < tempAttributes.count {
                    attributeController.remove(tempEntity: tempAttributes[indexPath.row])
                } else if let tempModules = moduleController.getTempModules(from: section.section),
                    indexPath.row < tempModules.count {
                    moduleController.remove(tempEntity: tempModules[indexPath.row])
                } else {
                    return
                }
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            characterHasBeenModified()
        }
    }
    
    //MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if attributeTypeSectionController?.sectionToShow(section - 1)?.section is ModuleType {
            return 2
        }
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        
        view.tag = section
        
        if section > 0 {
            let tap = UITapGestureRecognizer(target: self, action: #selector(toggleSection(_:)))
            view.addGestureRecognizer(tap)
        }
        
        view.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
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
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        view.tag = section + 1
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleSection(_:)))
        view.addGestureRecognizer(tap)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0,
            !editMode {
            return nil
        }
        
        if let section = attributeTypeSectionController?.sectionToShow(indexPath.section),
            let tempAttributes = attributeController.getTempAttributes(from: section.section) {
            return indexPath.row == tempAttributes.count ? indexPath : nil
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 0) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if let nameCell = tableView.cellForRow(at: indexPath) as? CharacterNameTableViewCell {
                nameCell.textField.becomeFirstResponder()
            }
        }
    }
    
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
        
        var sections: IndexSet = [index]
        
        let tempSection = attributeTypeSectionController?.sectionToShow(index)
        if tempSection?.section is ModuleType {
            sections.insert(index + 1)
        }
        
        attributeTypeSectionController?.toggleSection(index)
        if index < tableView.numberOfSections {
            tableView.reloadSections(sections, with: .automatic)
        }
    }
    
    @discardableResult private func save() -> Bool {
        guard let game = gameReference?.game,
            let name = name,
            !name.isEmpty,
            let race = race else { return false }
        
        guard let selectedSegmentIndex = femaleSegmentedControl?.selectedSegmentIndex else { return false }
        let female: Bool = selectedSegmentIndex == 0 ? false : true
        
        let context = CoreDataStack.shared.mainContext
        let savedCharacter: Character
        
        if let character = character {
            characterController?.edit(character: character, name: name, race: race, female: female, context: context)
            savedCharacter = character
        } else {
            guard let character = characterController?.create(character: name, race: race, female: female, game: game, context: context) else { return false }
            savedCharacter = character
        }
        
        attributeController.removeMissingTempAttributes(from: savedCharacter, context: context)
        attributeController.saveTempAttributes(to: savedCharacter, context: context)
        
        moduleController.removeMissingTempModules(from: savedCharacter, context: context)
        moduleController.saveTempModules(to: savedCharacter, context: context)
        
        attributeTypeSectionController?.saveTempSections(to: savedCharacter)
        
        gameReference?.isSafeToChangeGame = true
        return true
    }
    
    private func characterHasBeenModified() {
        gameReference?.isSafeToChangeGame = false
        
        if navigationItem.rightBarButtonItem?.tag != 3 {
            navigationItem.rightBarButtonItem = saveButton
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = (name != nil && name != "" && race != nil)
    }
    
    //MARK: Actions
    
    @objc private func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        guard save() else { return }
        
        if character == nil {
            dismiss(animated: true, completion: nil)
        } else {
            endEdit()
        }
    }
    
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func edit() {
        navigationItem.rightBarButtonItem = cancelEditButton
        editMode = true
        
        tableView.reloadData()
    }
    
    @objc private func endEdit() {
        editMode = false
        navigationItem.rightBarButtonItem = editButton
        view.endEditing(true)
        
        tableView.reloadData()
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "ShowRaces":
            return editMode
        default:
            return true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CharacterTrackerViewController {
            vc.gameReference = gameReference
            
            if let racesVC = vc as? RacesTableViewController {
                checkRace = true
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
                                let characterModules = character.modules as? Set<CharacterModule>
                                moduleDetailVC.characterModule = characterModules?.first(where: { $0.module == module })
                            }
                            
                            moduleDetailVC.moduleType = modulesSection
                            moduleDetailVC.callbacks.append { characterModule, completed in
                                self.moduleController.setCompleted(characterModule: characterModule, completed: completed, context: CoreDataStack.shared.mainContext)
                                if completed {
                                    DispatchQueue.main.async {
                                        self.navigationController?.popViewController(animated: true)
                                    }
                                }
                            }
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
                        characterIngredientsVC.character = character
                    }
                }
            }
        } else if let navigationController = segue.destination as? UINavigationController {
            if let sectionsVC = navigationController.viewControllers[0] as? SectionsTableViewController {
                sectionsVC.attributeTypeSectionController = attributeTypeSectionController
                sectionsVC.attributeController = attributeController
                sectionsVC.moduleController = moduleController
                sectionsVC.delegate = self
            }
        }
    }

}

//MARK: Text field delegate

extension CharacterDetailTableViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return editMode
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.attributedPlaceholder = NSAttributedString(string: "Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText])
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        name = textField.text
        
        if name != character?.name {
            characterHasBeenModified()
            
            if name?.isEmpty ?? true {
                textField.attributedPlaceholder = NSAttributedString(string: "Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemRed])
            }
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
        //characterHasBeenModified()
    }
}
