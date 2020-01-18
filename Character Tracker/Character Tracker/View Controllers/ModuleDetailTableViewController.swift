//
//  ModuleDetailTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/13/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

class ModuleDetailTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var completeView: UIView!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    //MARK: Properties
    
    var ingredientController = IngredientController()
    var moduleController = ModuleController()
    var gameReference: GameReference?
    var moduleType: ModuleType?
    var module: Module? {
        didSet {
            if let module = module, let game = gameReference?.game {
                ingredientController.fetchTempIngredients(for: module, in: game, context: CoreDataStack.shared.mainContext)
            }
        }
    }
    var characterModule: CharacterModule?
    var callbacks: [( (CharacterModule, Bool) -> Void )] = []
    
    enum SectionTypes: Equatable {
        case name
        case notes(TextViewReference)
        case ingredients
        case modules
    }
    
    var nameTextField: UITextField?
    var levelTextField: UITextField?
    var levelStepper: UIStepper?
    
    var sections: [(name: String, type: SectionTypes)] = []
    
    class TextViewReference: Equatable {
        static func == (lhs: TextViewReference, rhs: TextViewReference) -> Bool {
            return lhs.textView == rhs.textView
        }
        
        var textView: UITextView?
    }
    
    var notesTextView = TextViewReference()
    var characterNotesTextView = TextViewReference()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSections()
        
        completeButton.setTitle("Completed", for: .disabled)
        completeButton.setTitle("Complete", for: .normal)
        
        saveButton.isEnabled = false
        
        updateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        var sectionsToReload: IndexSet = []
        if let ingredientsSectionIndex = sections.firstIndex(where: { $0.type == .ingredients }) {
            sectionsToReload.insert(ingredientsSectionIndex)
        }
        if let modulesSectionIndex = sections.firstIndex(where: { $0.type == .modules }) {
            sectionsToReload.insert(modulesSectionIndex)
        }
        
        tableView.reloadSections(sectionsToReload, with: .automatic)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section].type {
        case .name:
            return 2
        case .notes(_):
            return 1
        case .ingredients:
            return ingredientController.tempIngredients.count + 1
        case .modules:
            return moduleController.tempModules.count + 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if module == nil {
                return 0
            }
            return 20
        }

        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        let type = sections[indexPath.section].type
        
        switch type {
        case .name:
            if indexPath.row == 0 {
                if let nameCell = tableView.dequeueReusableCell(withIdentifier: "ModuleNameCell", for: indexPath) as? ModuleNameTableViewCell {
                    nameTextField = nameCell.textField
                    nameTextField?.delegate = self
                    nameTextField?.text = module?.name
                    
                    cell = nameCell
                } else {
                    // This shouldn't ever be called
                    cell = tableView.dequeueReusableCell(withIdentifier: "ModuleNameCell", for: indexPath)
                }
            } else {
                if let levelCell = tableView.dequeueReusableCell(withIdentifier: "LevelCell", for: indexPath) as? LevelTableViewCell {
                    levelCell.callback = moduleHasBeenModified
                    
                    levelTextField = levelCell.textField
                    levelTextField?.delegate = self
                    
                    levelStepper = levelCell.stepper
                    
                    if let level = module?.level,
                        level > 0 {
                        levelTextField?.text = String(level)
                        levelStepper?.value = Double(level)
                    }
                    
                    cell = levelCell
                } else {
                    // This shouldn't ever be called
                    cell = tableView.dequeueReusableCell(withIdentifier: "LevelCell", for: indexPath)
                }
            }
        case .notes(let textViewReference):
            if let notesCell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath) as? NotesTableViewCell {
                let cellTextView = notesCell.textView
                cellTextView?.delegate = self
                
                switch textViewReference {
                case notesTextView:
                    notesTextView.textView = cellTextView
                    if let notes = module?.notes {
                        cellTextView?.text = notes
                    } else {
                        cellTextView?.text = nil
                    }
                case characterNotesTextView:
                    characterNotesTextView.textView = cellTextView
                    if let characterNotes = characterModule?.notes {
                        cellTextView?.text = characterNotes
                    } else {
                        cellTextView?.text = nil
                    }
                default:
                    break
                }
                
                cell = notesCell
            } else {
                // This shouldn't ever be called
                cell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath)
            }
        case .ingredients:
            if indexPath.row < ingredientController.tempIngredients.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)
                
                let tempIngredient = ingredientController.tempIngredients[indexPath.row]
                
                cell.textLabel?.text = tempIngredient.ingredient.name
                
                if tempIngredient.quantity != 0 {
                    cell.detailTextLabel?.text = "Qty: \(tempIngredient.quantity)"
                } else {
                    cell.detailTextLabel?.text = nil
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectIngredientCell", for: indexPath)
            }
        case .modules:
            if indexPath.row < moduleController.tempModules.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "ModuleDetailCell", for: indexPath)
                
                let tempModule = moduleController.tempModules[indexPath.row]
                let module = tempModule.module
                
                cell.textLabel?.text = module.name
                
                if module.level > 0 {
                    cell.detailTextLabel?.text = "Level \(module.level)"
                } else {
                    cell.detailTextLabel?.text = nil
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectModuleCell", for: indexPath)
                cell.textLabel?.text = "Select Modules"
            }
        }

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 2,
            indexPath.row < ingredientController.tempIngredients.count {
            return true
        }
        
        return false
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let ingredient = ingredientController.tempIngredients[indexPath.row].ingredient
            ingredientController.remove(tempIngredient: ingredient)
            tableView.deleteRows(at: [indexPath], with: .fade)
            moduleHasBeenModified()
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].type {
        case .notes(let textViewReference):
            if let textView = textViewReference.textView {
                setTextViewFontSize(textView)
            }
        default:
            break
        }
        
//        if indexPath == IndexPath(row: 0, section: 2) {
//            if let textView = notesTextView {
//                setTextViewFontSize(textView)
//            }
//        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        
        switch section.type {
        case .name:
            tableView.deselectRow(at: indexPath, animated: true)
            if let nameCell = tableView.cellForRow(at: indexPath) as? ModuleNameTableViewCell {
                nameCell.textField.becomeFirstResponder()
            }
        case .notes(_):
            tableView.deselectRow(at: indexPath, animated: true)
            if let notesCell = tableView.cellForRow(at: indexPath) as? NotesTableViewCell {
                notesCell.textView.becomeFirstResponder()
            }
        default:
            break
        }
    }
    
    //MARK: Private
    
    private func choose(characterModule: CharacterModule, completed: Bool) {
        for callback in callbacks {
            callback(characterModule, completed)
        }
    }
    
    private func setUpSections() {
        sections.append(("", .name))
        
        if let moduleTypeName = moduleType?.name {
            sections.append(("\(moduleTypeName) Description", .notes(notesTextView)))
        } else {
            sections.append(("Module Description", .notes(notesTextView)))
        }
        
        if let character = characterModule?.character {
            if let characterName = character.name {
                sections.append(("\(characterName) Notes", .notes(characterNotesTextView)))
            } else {
                sections.append(("Character Notes", .notes(characterNotesTextView)))
            }
        }
        
        sections.append(("Ingredients", .ingredients))
        sections.append(("Required Modules", .modules))
    }
    
    private func updateViews() {
        
        if let module = module {
            title = module.name
        } else {
            title = "New Module"
            completeView.isHidden = true
        }
        
        if let completed = characterModule?.completed {
            if completed {
                completeButton.isEnabled = false
                undoButton.isHidden = false
            } else {
                completeButton.isEnabled = true
                undoButton.isHidden = true
            }
        } else {
            undoButton.isHidden = true
            completeButton.isEnabled = false
            completeButton.setTitle("Save to a character to add notes", for: .disabled)
        }
        
    }
    
    private func setTextViewFontSize(_ textView: UITextView) {
        let numLines = Int(textView.contentSize.height / textView.font!.lineHeight)
        
        if numLines < 3, textView.font!.pointSize < 17.0 {
            textView.font = UIFont(descriptor: textView.font!.fontDescriptor, size: 17.0)
        } else if numLines > 3, textView.font!.pointSize > 14.0 {
            textView.font = UIFont(descriptor: textView.font!.fontDescriptor, size: 14.0)
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    private func prompt(message: String) {
        let alertController = UIAlertController(title: "Could not save module", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func save() {
        guard let game = gameReference?.game,
            let type = moduleType else { return }
        let context = CoreDataStack.shared.mainContext
        
        guard let name = nameTextField?.text,
            !name.isEmpty else {
                prompt(message: "Please enter a module name.")
                return
        }
        
        let level = Int16(levelTextField?.text ?? "")
        
        let savedModule: Module
        
        if let module = module {
            moduleController.edit(module: module, name: name, notes: notesTextView.textView?.text, level: level ?? 0, type: type, context: context)
            savedModule = module
        } else {
            let module = moduleController.create(module: name, notes: notesTextView.textView?.text, level: level ?? 0, game: game, type: type, context: context)
            savedModule = module
        }
        
        if let characterModule = characterModule {
            characterModule.notes = characterNotesTextView.textView?.text
        }
        
        ingredientController.removeMissingTempIngredients(from: savedModule, context: context)
        ingredientController.saveTempIngredients(to: savedModule, context: context)
    }
    
    private func setCompleted(_ completed: Bool) {
        if let characterModule = characterModule {
            choose(characterModule: characterModule, completed: completed)
        }
    }
    
    private func moduleHasBeenModified() {
        //gameReference?.isSafeToChangeGame = false
        saveButton.isEnabled = true
    }
    
    //MARK: Actions
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        save()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func completeTapped(_ sender: UIButton) {
        setCompleted(true)
        updateViews()
    }
    
    @IBAction func undoTapped(_ sender: UIButton) {
        setCompleted(false)
        updateViews()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CharacterTrackerViewController {
            vc.gameReference = gameReference
            
            if let ingredientsVC = vc as? IngredientsTableViewController {
                ingredientsVC.ingredientController = ingredientController
                ingredientsVC.callbacks.append { ingredient in
                    ingredientsVC.askForQuantity { quantity in
                        if let quantity = quantity {
                            self.ingredientController.add(tempIngredient: ingredient, quantity: quantity)
                            self.moduleHasBeenModified()
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            } else if let modulesVC = vc as? ModulesTableViewController {
                let selectedModules = moduleController.tempModules.map({ $0.module })
                
                modulesVC.checkedModules = selectedModules
                modulesVC.moduleController = moduleController
                
                modulesVC.callbacks.append { module in
                    self.moduleController.toggle(tempModule: module)
                    self.moduleHasBeenModified()
                }
            }
        }
    }

}

// MARK: Text Field Delegate

extension ModuleDetailTableViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == levelTextField {
            if let level = Int(textField.text ?? "") {
                // Valid integer. Set the stepper to it
                levelStepper?.value = Double(level)
                moduleHasBeenModified()
            } else if textField.text == "" {
                // Empty. Set the stepper to 0
                levelStepper?.value = 0
                moduleHasBeenModified()
            } else {
                // Garbage. Set the text field back to what the stepper is
                if let level = levelStepper?.value,
                    level > 0 {
                    textField.text = String(Int(level))
                } else {
                    textField.text = ""
                }
            }
        } else if textField == nameTextField {
            if textField.text != module?.name {
                moduleHasBeenModified()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

//MARK: Text View Delegate

extension ModuleDetailTableViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        setTextViewFontSize(textView)
        moduleHasBeenModified()
    }
    
}
