//
//  UIPopoverPresentationController+Convenience.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/21/21.
//  Copyright © 2021 Isaac Lyons. All rights reserved.
//

import UIKit

extension UIPopoverPresentationController {
    func setSource(_ source: UIView, button: UIView) {
        sourceView = source
        sourceRect = button.convert(button.bounds, to: source)
    }
}

extension UIViewController {
    func setPopover(source: UIView, button: UIView) {
        popoverPresentationController?.setSource(source, button: button)
    }
}
