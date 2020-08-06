//
//  ModuleDetailTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/13/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import SwiftUI

class ModuleDetailTableViewController: UITableViewController, CharacterTrackerViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var completeView: UIView!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var exportView: UIView!
    @IBOutlet weak var exportButton: UIButton!
    
    //MARK: Properties
    
    let moduleController = ModuleController()
    let attributeController = AttributeController()
    var ingredientController = IngredientController()
    var gameReference: GameReference? {
        didSet {
            if let game = gameReference?.game {
                games = [game]
            }
        }
    }
    var moduleType: ModuleType?
    var module: Module? {
        didSet {
            if let module = module,
                let currentGame = gameReference?.game {
                self.name = module.name
                let context = CoreDataStack.shared.mainContext
                let games = module.mutableSetValue(forKey: "games")
                if let gamesArray = games.sortedArray(using: [NSSortDescriptor(key: "index", ascending: true)]) as? [Game] {
                    self.games = gamesArray
                }
                ingredientController.fetchTempIngredients(for: module, in: currentGame, context: context)
                moduleController.fetchTempModules(for: module, game: currentGame, context: context)
                attributeController.fetchTempAttributes(for: module, context: context)
            }
        }
    }
    var characterModule: CharacterModule?
    var excludedModules: [Module] = []
    var games: [Game] = []
    var name: String?
    var editMode: Bool = false
    var callbacks: [( (CharacterModule, Bool) -> Void )] = []
    
    enum SectionTypes: Equatable {
        case name
        case notes(TextViewReference)
        case ingredients
        case modules
        case attributes
        case games
    }
    
    var sections: [(name: String, type: SectionTypes)] = []
    var sectionsToReload: [SectionTypes] = []
    
    weak var nameTextField: UITextField?
    weak var levelTextField: UITextField?
    weak var levelStepper: UIStepper?
    
    weak var cancelButton: UIBarButtonItem? {
        let barButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        barButton.tag = 1
        return barButton
    }
    weak var editButton: UIBarButtonItem? {
        let barButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        barButton.tag = 2
        return barButton
    }
    weak var saveButton: UIBarButtonItem? {
        let barButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped(_:)))
        barButton.tag = 3
        return barButton
    }
    weak var cancelEditButton: UIBarButtonItem? {
        let barButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(endEdit))
        barButton.tag = 4
        return barButton
    }
    
    class TextViewReference: Equatable {
        static func == (lhs: TextViewReference, rhs: TextViewReference) -> Bool {
            return lhs.textView == rhs.textView
        }
        
        weak var textView: UITextView?
    }
    
    var notesTextView = TextViewReference()
    var characterNotesTextView = TextViewReference()
    
    //MARK: View loading

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSections()
        
        completeButton.setTitle("Completed", for: .disabled)
        completeButton.setTitle("Complete", for: .normal)
        
        if module == nil {
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
        
        if let characterModule = characterModule {
            moduleController.checkTempModules(againstCharacterFrom: characterModule, context: CoreDataStack.shared.mainContext)
        }

        var sectionIndicesToReload: IndexSet = []
        for section in sectionsToReload {
            guard let index = sections.firstIndex(where: { $0.type == section }) else { continue }
            sectionIndicesToReload.insert(index)
        }
        
        tableView.reloadSections(sectionIndicesToReload, with: .automatic)
        sectionsToReload = []
    }

    //MARK: Table view data source

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
            return ingredientController.tempEntities.count + editMode.int
        case .modules:
            return moduleController.tempEntities.count + editMode.int
        case .attributes:
            return attributeController.tempEntities.count + editMode.int
        case .games:
            return games.count + editMode.int
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
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
                    nameTextField?.text = name
                    
                    cell = nameCell
                } else {
                    // This shouldn't ever be called
                    cell = tableView.dequeueReusableCell(withIdentifier: "ModuleNameCell", for: indexPath)
                }
            } else {
                if let levelCell = tableView.dequeueReusableCell(withIdentifier: "LevelCell", for: indexPath) as? LevelTableViewCell {
                    levelCell.delegate = self
                    
                    levelTextField = levelCell.textField
                    levelTextField?.delegate = self
                    
                    levelStepper = levelCell.stepper
                    levelStepper?.isEnabled = editMode
                    
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
                cellTextView?.isEditable = editMode
                cellTextView?.isScrollEnabled = editMode
                
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
            if indexPath.row < ingredientController.tempEntities.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)
                
                let tempIngredient = ingredientController.tempEntities[indexPath.row]
                
                cell.textLabel?.text = tempIngredient.entity.name
                
                if tempIngredient.value != 0 {
                    cell.detailTextLabel?.text = "Qty: \(tempIngredient.value)"
                } else {
                    cell.detailTextLabel?.text = nil
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectIngredientCell", for: indexPath)
            }
        case .modules:
            if indexPath.row < moduleController.tempEntities.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "ModuleDetailCell", for: indexPath)
                
                let tempModule = moduleController.tempEntities[indexPath.row]
                let module = tempModule.entity
                
                cell.textLabel?.text = module.name
                
                if module.level > 0 {
                    cell.detailTextLabel?.text = "Level \(module.level)"
                } else {
                    cell.detailTextLabel?.text = nil
                }
                
                if tempModule.value {
                    cell.accessoryType = .checkmark
                    cell.tintColor = .systemGreen
                } else {
                    cell.tintColor = .systemBlue
                    if moduleIsExcluded(at: indexPath) {
                        cell.accessoryType = .none
                    } else {
                        cell.accessoryType = .disclosureIndicator
                    }
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectModuleCell", for: indexPath)
                cell.textLabel?.text = "Select Modules"
            }
        case .attributes:
            if indexPath.row < attributeController.tempEntities.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)
                cell.textLabel?.text = attributeController.tempEntities[indexPath.row].entity.name
                cell.detailTextLabel?.text = nil
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectAttributeCell", for: indexPath)
            }
        case .games:
            if indexPath.row < games.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)
                cell.textLabel?.text = games[indexPath.row].name
                cell.detailTextLabel?.text = nil
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SelectGameCell", for: indexPath)
            }
        }

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard editMode else { return false }
        
        let array: [Any]
        switch sections[indexPath.section].type {
        case .ingredients:
            array = ingredientController.tempEntities
        case .modules:
            array = moduleController.tempEntities
        case .attributes:
            array = attributeController.tempEntities
        case .games where games.firstIndex(where: { $0 == gameReference?.game }) != indexPath.row:
            array = games
        default:
            return false
        }
        return indexPath.row < array.count
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let section = sections[indexPath.section].type
            switch section {
            case .ingredients:
                let ingredient = ingredientController.tempEntities[indexPath.row].entity
                ingredientController.remove(tempEntity: ingredient)
            case .modules:
                let module = moduleController.tempEntities[indexPath.row].entity
                moduleController.remove(tempEntity: module)
            case .attributes:
                let attribute = attributeController.tempEntities[indexPath.row].entity
                attributeController.remove(tempEntity: attribute)
            case .games:
                games.remove(at: indexPath.row)
            default:
                break
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
            moduleHasBeenModified()
        }  
    }
    
    //MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if module == nil {
                return 0
            }
            return 20
        }

        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if editMode,
            case .notes = sections[indexPath.section].type {
            return 144
        }
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let section = sections[indexPath.section].type
        
        let array: [Any]
        switch section {
        case .attributes:
            array = attributeController.tempEntities
        case .games:
            array = games
        case .name:
            array = []
        default:
            return indexPath
        }
        
        return indexPath.row == array.count ? indexPath : nil
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
        case .modules:
            if moduleIsExcluded(at: indexPath) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        case .ingredients:
            if indexPath.row < ingredientController.tempEntities.count {
                let ingredient = ingredientController.tempEntities[indexPath.row].entity
                tableView.deselectRow(at: indexPath, animated: true)
                prompt(title: ingredient.name ?? "Ingredient", message: "Plugin and FormID:\n\(ingredient.id ?? "")")
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
        sections.append(("Attributes", .attributes))
        sections.append(("Games", .games))
    }
    
    private func updateViews() {
        
        if let module = module {
            title = module.name
        } else {
            completeView.isHidden = true
            if let typeName = moduleType?.typeName {
                title = "New \(typeName)"
            } else {
                title = "New Module"
            }
        }
        
        if let completed = characterModule?.completed {
            completeButton.isEnabled = !completed
            undoButton.isHidden = !completed
        } else {
            undoButton.isHidden = true
            completeButton.isEnabled = false
            completeButton.setTitle("Save to a character to add notes", for: .disabled)
        }
        
        if editMode {
            exportView.isHidden = true
            exportButton.isEnabled = false
        } else {
            exportButton.isEnabled = true
            exportView.isHidden = false
        }
        
    }
    
    private func prompt(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    @discardableResult private func save() -> Bool {
        guard let type = moduleType,
            let name = nameTextField?.text,
            !name.isEmpty,
            !games.isEmpty else { return false }
        
        let context = CoreDataStack.shared.mainContext
        
        let level = Int16(levelTextField?.text ?? "")
        
        let savedModule: Module
        
        if let module = module {
            moduleController.edit(module: module, name: name, notes: notesTextView.textView?.text, level: level ?? 0, games: games, type: type, context: context)
            savedModule = module
        } else {
            let module = moduleController.create(module: name, notes: notesTextView.textView?.text, level: level ?? 0, games: games, type: type, context: context)
            savedModule = module
        }
        
        if let characterModule = characterModule {
            characterModule.notes = characterNotesTextView.textView?.text
        }
        
        ingredientController.removeMissingTempIngredients(from: savedModule, context: context)
        ingredientController.saveTempIngredients(to: savedModule, context: context)
        
        moduleController.removeMissingTempModules(from: savedModule, context: context)
        moduleController.saveTempModules(to: savedModule, context: context)
        
        attributeController.removeMissingTempAttributes(from: savedModule, context: context)
        attributeController.saveTempAttributes(to: savedModule, context: context)
        
        return true
    }
    
    private func setCompleted(_ completed: Bool) {
        if let characterModule = characterModule {
            choose(characterModule: characterModule, completed: completed)
        }
    }
    
    private func moduleHasBeenModified() {
        //gameReference?.isSafeToChangeGame = false
        
        if navigationItem.rightBarButtonItem?.tag != 3 {
            navigationItem.rightBarButtonItem = saveButton
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = !(name?.isEmpty ?? true)
    }
    
    private func moduleIsExcluded(at indexPath: IndexPath) -> Bool {
        let index = indexPath.row
        
        if index >= moduleController.tempEntities.count {
            return false
        }
        
        let module = moduleController.tempEntities[index].entity
        if excludedModules.contains(module) {
            return true
        }
        
        return false
    }
    
    private func markSectionForReload(section: SectionTypes) {
        if !sectionsToReload.contains(section) {
            sectionsToReload.append(section)
        }
    }
    
    //MARK: Actions
    
    @objc private func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        guard save() else { return }
        
        if module == nil {
            dismiss(animated: true, completion: nil)
        } else {
            endEdit()
        }
    }
    
    @IBAction func completeTapped(_ sender: UIButton) {
        setCompleted(true)
        updateViews()
    }
    
    @IBAction func undoTapped(_ sender: UIButton) {
        setCompleted(false)
        updateViews()
    }
    
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
        updateViews()
    }
    
    @objc private func edit() {
        navigationItem.rightBarButtonItem = cancelEditButton
        editMode = true
        
        tableView.reloadData()
        updateViews()
    }
    
    @objc private func endEdit() {
        editMode = false
        navigationItem.rightBarButtonItem = editButton
        view.endEditing(true)
        
        tableView.reloadData()
        updateViews()
    }
    
    @IBAction func export(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Export \(module?.name ?? "Module")", message: nil, preferredStyle: .actionSheet)
        
        let qrCode = UIAlertAction(title: "QR Code", style: .default) { _ in
            self.qrCode()
        }
        
        let json = UIAlertAction(title: "JSON", style: .default) { _ in
            guard let module = self.module,
                let json = PortController.shared.jsonString(for: module) else { return }
            let activityVC = UIActivityViewController(activityItems: [json], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
        
        let jsonFile = UIAlertAction(title: "JSON File", style: .default) { _ in
            guard let module = self.module,
                let url = PortController.shared.saveTempJSON(for: module) else { return }
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        actionSheet.addAction(qrCode)
        actionSheet.addAction(json)
        actionSheet.addAction(jsonFile)
        actionSheet.addAction(cancel)
        actionSheet.pruneNegativeWidthConstraints()
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            let buttonBounds = exportButton.convert(exportButton.bounds, to: self.view)
            popoverController.sourceRect = buttonBounds
        }
        
        present(actionSheet, animated: true)
    }
    
    private func qrCode() {
        guard let module = module,
            let qrCode = PortController.shared.exportToQRCode(for: module) else { return }
        
        let qrCodeView = UIHostingController(rootView:
            NavigationView {
                QRCodeView(name: self.module?.name, qrCode: qrCode, delegate: self)
            }
        )
        
        present(qrCodeView, animated: true)
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "AttributeToAttributes",
            let indexPath = tableView.indexPathForSelectedRow {
            if moduleIsExcluded(at: indexPath) {
                return false
            }
        }
        
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CharacterTrackerViewController {
            vc.gameReference = gameReference
            
            if let ingredientsVC = vc as? IngredientsTableViewController {
                ingredientsVC.ingredientController = ingredientController
                ingredientsVC.delegate = self
            } else if let modulesVC = vc as? ModulesTableViewController {
                let selectedModules = moduleController.tempEntities.map({ $0.entity })
                
                modulesVC.moduleController = moduleController
                modulesVC.checkedModules = selectedModules
                modulesVC.excludedModule = module
                
                modulesVC.callbacks.append { module in
                    self.moduleController.toggle(tempModule: module)
                    self.markSectionForReload(section: .modules)
                    self.moduleHasBeenModified()
                }
            } else if let attributesVC = vc as? AttributesTableViewController {
                let selectedAttributes = attributeController.tempEntities.map({ $0.entity })
                
                attributesVC.attributeController = attributeController
                attributesVC.checkedAttributes = selectedAttributes
                
                attributesVC.callbacks.append { attribute in
                    self.attributeController.toggle(tempAttribute: attribute, priority: 0)
                    self.markSectionForReload(section: .attributes)
                    self.moduleHasBeenModified()
                }
            } else if let gamesVC = vc as? GamesTableViewController {
                gamesVC.checkedGames = games
                gamesVC.callback = { games in
                    self.games = games
                    self.markSectionForReload(section: .games)
                    self.moduleHasBeenModified()
                }
            } else if let moduleDetailVC = vc as? ModuleDetailTableViewController,
                let indexPath = tableView.indexPathForSelectedRow {
                let tempModule = moduleController.tempEntities[indexPath.row]
                let module = tempModule.entity
                
                moduleDetailVC.module = module
                
                moduleDetailVC.excludedModules = excludedModules
                if let thisModule = self.module {
                    moduleDetailVC.excludedModules.append(thisModule)
                }
                
                if let character = characterModule?.character {
                    let characterModules = character.modules as? Set<CharacterModule>
                    moduleDetailVC.characterModule = characterModules?.first(where: { $0.module == module })
                }
                
                moduleDetailVC.moduleType = module.type
                moduleDetailVC.callbacks.append { characterModule, completed in
                    self.moduleController.setCompleted(characterModule: characterModule, completed: completed, context: CoreDataStack.shared.mainContext)
                    self.markSectionForReload(section: .modules)
                    if completed {
                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }
    }

}

// MARK: Text Field Delegate

extension ModuleDetailTableViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return editMode
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.attributedPlaceholder = NSAttributedString(string: "Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText])
    }
    
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
            name = textField.text
            
            if name != module?.name {
                moduleHasBeenModified()
                
                if name?.isEmpty ?? true {
                    textField.attributedPlaceholder = NSAttributedString(string: "Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemRed])
                }
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
        moduleHasBeenModified()
    }
    
}

//MARK: Ingredients table delegate

extension ModuleDetailTableViewController: IngredientsTableDelegate {
    func choose(ingredient: Ingredient, quantity: Int16) {
        self.ingredientController.add(tempEntity: ingredient, value: quantity)
        self.markSectionForReload(section: .ingredients)
        self.moduleHasBeenModified()
        self.navigationController?.popViewController(animated: true)
    }
}

//MARK: Level table view cell delegate

extension ModuleDetailTableViewController: LevelTableViewCellDelegate {
    func levelChanged() {
        moduleHasBeenModified()
    }
}

//MARK: SwiftUIModalDelegate

extension ModuleDetailTableViewController: SwiftUIModalDelegate {
    func dismiss() {
        dismiss(animated: true)
    }
}
