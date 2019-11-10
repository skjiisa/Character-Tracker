//
//  UIAlertController+Fixes.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 11/9/19.
//  Copyright © 2019 Isaac Lyons. All rights reserved.
//

import UIKit

extension UIAlertController {
    // The following is to fix a bug with action sheet alerts
    func pruneNegativeWidthConstraints() {
        for subView in self.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}
