//
//  CharacterTrackerViewController.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/17/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import UIKit

protocol CharacterTrackerViewController: UIViewController {
    var gameReference: GameReference? { get set }
}
