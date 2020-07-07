//
//  LevelTableViewCell.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/13/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

protocol LevelTableViewCellDelegate: class {
    func levelChanged()
}

class LevelTableViewCell: UITableViewCell {
    
    //MARK: Outlets
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var stepper: UIStepper!
    
    //MARK: Properties
    
    weak var delegate: LevelTableViewCellDelegate?
    
    //MARK: Actions

    @IBAction func changeLevel(_ sender: UIStepper) {
        let level = Int(sender.value)
        if level == 0 {
            textField.text = ""
        } else {
            textField.text = String(level)
        }
        delegate?.levelChanged()
    }
    
}
