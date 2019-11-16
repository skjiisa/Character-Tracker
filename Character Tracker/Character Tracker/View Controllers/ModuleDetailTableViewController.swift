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
    var gameReference: GameReference?
    var moduleType: ModuleType?
    var module: Module? {
        didSet {
            if let module = module {
                ingredientController.fetchTempIngredients(for: module, context: CoreDataStack.shared.mainContext)
            }
        }
    }
    var characterModule: CharacterModule?
    var moduleController: ModuleController?
    
    var nameTextField: UITextField?
    var levelTextField: UITextField?
    var levelStepper: UIStepper?
    var notesTextView: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        completeButton.setTitle("Completed", for: .disabled)
        completeButton.setTitle("Complete", for: .normal)
        
        saveButton.isEnabled = false
        
        updateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 1
        }
        
        return ingredientController.tempIngredients.count + 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Notes"
        } else if section == 2 {
            return "Ingredients"
        }
        
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if indexPath.section == 0 {
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
        } else if indexPath.section == 1 {
            if let notesCell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath) as? NotesTableViewCell {
                notesTextView = notesCell.textView
                notesTextView?.delegate = self
                
                if let notes = module?.notes {
                    notesTextView?.text = notes
                } else {
                    notesTextView?.text = nil
                }
                
                cell = notesCell
            } else {
                // This shouldn't ever be called
                cell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath)
            }
        } else {
            if indexPath.row < ingredientController.tempIngredients.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)
                
                let tempIngredient = ingredientController.tempIngredients[indexPath.row]
                cell.textLabel?.text = tempIngredient.ingredient.name
                cell.detailTextLabel?.text = "\(tempIngredient.quantity)"
                if tempIngredient.completed {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectIngredientCell", for: indexPath)
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
        if indexPath == IndexPath(row: 0, section: 2) {
            if let textView = notesTextView {
                setTextViewFontSize(textView)
            }
        }
    }
    
    //MARK: Private
    
    private func updateViews() {
        
        if let module = module {
            title = module.name
        } else {
            title = "New Module"
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
            completeView.isHidden = true
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
            moduleController?.edit(module: module, name: name, notes: notesTextView?.text, level: level ?? 0, type: type, context: context)
            savedModule = module
        } else {
            guard let module = moduleController?.create(module: name, notes: notesTextView?.text, level: level ?? 0, game: game, type: type, context: context) else { return }
            savedModule = module
        }
        
        ingredientController.removeMissingTempIngredients(from: savedModule, context: context)
        ingredientController.saveTempIngredients(to: savedModule, context: context)
    }
    
    private func setCompleted(_ completed: Bool) {
        if let characterModule = characterModule {
            moduleController?.setCompleted(characterModule: characterModule, completed: completed, context: CoreDataStack.shared.mainContext)
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
        navigationController?.popViewController(animated: true)
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
                    self.ingredientController.add(tempIngredient: ingredient)
                    self.moduleHasBeenModified()
                    self.navigationController?.popViewController(animated: true)
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
