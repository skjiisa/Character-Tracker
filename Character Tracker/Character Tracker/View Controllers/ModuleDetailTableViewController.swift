//
//  ModuleDetailTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/13/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

class ModuleDetailTableViewController: UITableViewController, CharacterTrackerViewController {
    
    var gameReference: GameReference?
    var module: Module?
    
    var nameTextField: UITextField?
    var levelTextField: UITextField?
    var levelStepper: UIStepper?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        if let module = module {
            title = module.name
        } else {
            title = "New Module"
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 1
        }
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
                    levelTextField = levelCell.textField
                    levelTextField?.delegate = self
                    
                    levelStepper = levelCell.stepper
                    
                    cell = levelCell
                } else {
                    // This shouldn't ever be called
                    cell = tableView.dequeueReusableCell(withIdentifier: "LevelCell", for: indexPath)
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath)
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

extension ModuleDetailTableViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == levelTextField {
            if let level = Int(textField.text ?? "") {
                // Valid integer. Set the stepper to it
                levelStepper?.value = Double(level)
            } else if textField.text == "" {
                // Empty. Set the stepper to 0
                levelStepper?.value = 0
            } else {
                // Garbage. Set the text field back to what the stepper is
                if let level = levelStepper?.value {
                    textField.text = String(Int(level))
                } else {
                    textField.text = ""
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
