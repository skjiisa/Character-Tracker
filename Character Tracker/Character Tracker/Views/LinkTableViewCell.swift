//
//  LinkTableViewCell.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 3/16/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import UIKit

class LinkTableViewCell: UITableViewCell {
    
    @IBOutlet weak var button: UIButton!
    
    var title: String?
    var url: URL?
    
    @IBAction func openLink(_ sender: Any) {
        guard let url = url else { return }
        UIApplication.shared.open(url)
    }
    
}
