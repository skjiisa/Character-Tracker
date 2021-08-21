//
//  SwiftUIModalDelegate.swift
//  Character Tracker
//
//  Created by Elaine Lyons on 8/21/21.
//

import SwiftUI
import CoreData

protocol SwiftUIModalDelegate: UIViewController {
    func dismiss()
}

extension SwiftUIModalDelegate {
    func dismiss() {
        dismiss(animated: true)
    }
    
    func export<ObjectType: NSManagedObject>(_ object: ObjectType, name: String, button: UIView, parent: UIView) {
        let actionSheet = UIAlertController(title: "Export \(name)", message: nil, preferredStyle: .actionSheet)
        
        let qrCodeAction = UIAlertAction(title: "QR Codes", style: .default) { [weak self] _ in
            self?.qrCodes(object, name: name)
        }
        
        let json = UIAlertAction(title: "JSON Text", style: .default) { [weak self] _ in
            guard let json = PortController.shared.exportJSONText(for: object) else { return }
            let activityVC = UIActivityViewController(activityItems: [json], applicationActivities: nil)
            self?.present(activityVC, animated: true)
        }
        
        let jsonFile = UIAlertAction(title: "JSON File", style: .default) { [weak self] _ in
            guard let url = PortController.shared.saveTempJSON(for: object) else { return }
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                PortController.shared.clearFilesFromTempDirectory()
            }
            self?.present(activityVC, animated: true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        actionSheet.addAction(qrCodeAction)
        actionSheet.addAction(json)
        actionSheet.addAction(jsonFile)
        actionSheet.addAction(cancel)
        actionSheet.pruneNegativeWidthConstraints()
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            let buttonBounds = button.convert(button.bounds, to: parent)
            popoverController.sourceRect = buttonBounds
        }
        
        present(actionSheet, animated: true)
    }
    
    private func qrCodes<ObjectType: NSManagedObject>(_ object: ObjectType, name: String) {
        // Show loading toast
        let alert = UIAlertController(title: nil, message: "Generating QR Codes", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        present(alert, animated: true) {
            dispatchGroup.leave()
        }
        
        // Generate the QR codes on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let codes = PortController.shared.exportToQRCodes(for: object),
                  let qrCodes = QRCodes(codes) else { return }
            
            let qrCodeView = UIHostingController(
                rootView:
                    NavigationView {
                        QRCodeView(name: name, qrCodes: qrCodes, delegate: self)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
            )
            
            dispatchGroup.notify(queue: .main) { [weak self] in
                // Dismiss the loading toast
                self?.dismiss(animated: true) {
                    // Does this run on the mean thread?
                    self?.present(qrCodeView, animated: true)
                }
            }
        }
    }
}
