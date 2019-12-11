//
//  SectionsTableViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/7/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

protocol SectionsTableDelegate {
    func updateSections()
}

class SectionsTableViewController: UITableViewController {
    
    //MARK: Properties

    var attributeTypeSectionController: AttributeTypeSectionController?
    var attributeController: AttributeController?
    var moduleController: ModuleController?
    var character: Character?
    var delegate: SectionsTableDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attributeTypeSectionController?.sections.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SectionCell", for: indexPath)

        if let section = attributeTypeSectionController?.sections[indexPath.row] {
            cell.textLabel?.text = section.name
            
            if attributeTypeSectionController?.contains(section: section) ?? false {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            if let attributeSection = section as? AttributeTypeSection,
                let tempAttributes = attributeController?.getTempAttributes(from: attributeSection),
                tempAttributes.count > 0 {
                cell.detailTextLabel?.text = "\(tempAttributes.count) item\(tempAttributes.count > 1 ? "s" : "")"
            } else if let moduleSection = section as? ModuleType,
                let tempModules = moduleController?.getTempModules(from: moduleSection),
                tempModules.count > 0 {
                cell.detailTextLabel?.text = "\(tempModules.count) item\(tempModules.count > 1 ? "s" : "")"
            } else {
                cell.detailTextLabel?.text = nil
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = attributeTypeSectionController?.sections[indexPath.row] else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.accessoryType == .none {
                cell.accessoryType = .checkmark
                attributeTypeSectionController?.tempSectionsToShow.append(TempSection(section: section))
                delegate?.updateSections()
            } else {
                cell.accessoryType = .none
                attributeTypeSectionController?.remove(section: section)
                delegate?.updateSections()
            }
        }
    }
    
    //MARK: Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
