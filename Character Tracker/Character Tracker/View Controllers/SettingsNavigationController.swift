//
//  SettingsNavigationController.swift
//  Character Tracker
//
//  Created by Elaine Lyons on 8/20/21.
//

import UIKit

class SettingsNavigationController: UINavigationController {

    // This is to fix a weird behavior where SwiftUI views that are children of UINavigationController (as opposed to a SwiftUI NavigationView), set that navigation controller's title with the .navigationTitle() modifier, changing the tab bar icon.
    override var title: String? {
        get {
            "Settings"
        }
        set {}
    }

}
