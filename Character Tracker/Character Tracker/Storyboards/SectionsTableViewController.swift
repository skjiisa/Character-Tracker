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

    var attributeTypeSectionController: AttributeTypeSectionController? {
        didSet {
            sortSections()
        }
    }
    var attributeController: AttributeController?
    var moduleController: ModuleController?
    var character: Character?
    var delegate: SectionsTableDelegate?
    
    var shownSections: [Section] = []
    var hiddenSections: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Shown sections"
        }
        
        return "Hidden sections"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return shownSections.count
        }
        
        return hiddenSections.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SectionCell", for: indexPath)

        let section: Section
        if indexPath.section == 0 {
            section = shownSections[indexPath.row]
        } else {
            section = hiddenSections[indexPath.row]
        }
        
        cell.textLabel?.text = section.name
        
//        if attributeTypeSectionController?.contains(section: section) ?? false {
//            cell.accessoryType = .checkmark
//        } else {
//            cell.accessoryType = .none
//        }
        
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
        //guard let section = attributeTypeSectionController?.sections[indexPath.row] else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
//        if let cell = tableView.cellForRow(at: indexPath) {
//            if cell.accessoryType == .none {
//                cell.accessoryType = .checkmark
//                attributeTypeSectionController?.tempSectionsToShow.append(TempSection(section: section))
//                delegate?.updateSections()
//            } else {
//                cell.accessoryType = .none
//                attributeTypeSectionController?.remove(section: section)
//                delegate?.updateSections()
//            }
//        }
        
        if indexPath.section == 0 {
            let section = shownSections[indexPath.row]
            attributeTypeSectionController?.remove(section: section)
            delegate?.updateSections()
            shownSections.remove(at: indexPath.row)
            hiddenSections.insert(section, at: 0)
            tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 1))
        } else {
            let section = hiddenSections[indexPath.row]
            attributeTypeSectionController?.tempSectionsToShow.append(TempSection(section: section))
            delegate?.updateSections()
            hiddenSections.remove(at: indexPath.row)
            shownSections.append(section)
            tableView.moveRow(at: indexPath, to: IndexPath(row: shownSections.count - 1, section: 0))
        }
    }
    
    //MARK: Private
    
    func sortSections() {
        guard let attributeTypeSectionController = attributeTypeSectionController else { return }
        
        shownSections = attributeTypeSectionController.sections.filter({ attributeTypeSectionController.contains(section: $0) })
        hiddenSections = attributeTypeSectionController.sections.filter({ !attributeTypeSectionController.contains(section: $0) })
    }
    
    //MARK: Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
