//
//  CharacterNameTableViewCell.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/4/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

protocol CharacterNameCellDelegate {
    func valueChanged(_ sender: UISegmentedControl)
}

class CharacterNameTableViewCell: UITableViewCell {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var femaleSegmentedControl: UISegmentedControl!
    
    var delegate: CharacterNameCellDelegate?
    
    @IBAction func femaleChanged(_ sender: UISegmentedControl) {
        delegate?.valueChanged(sender)
    }
}