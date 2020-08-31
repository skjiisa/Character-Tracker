//
//  ScannerView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/31/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ScannerViewController
    
    @Binding var showing: Bool
    @Binding var alert: Alert?
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerVC = ScannerViewController()
        scannerVC.delegate = context.coordinator
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    class Coordinator: ScannerViewControllerDelegate {
        var parent: ScannerView
        
        init(_ parent: ScannerView) {
            self.parent = parent
        }
        
        func found(code: String) {
            let context = CoreDataStack.shared.container.newBackgroundContext()
            
            context.performAndWait {
                let importedNames = PortController.shared.importOnBackgroundContext(string: code, context: context)
                
                let save = Alert.Button.default(Text("Save")) {
                    CoreDataStack.shared.save(context: context)
                }
                
                let alert = Alert(title: Text("Imported objects"),
                                  message: Text(importedNames.joined(separator: ", ")),
                                  primaryButton: save,
                                  secondaryButton: Alert.Button.cancel())
                
                DispatchQueue.main.async {
                    self.parent.showing = false
                    self.parent.alert = alert
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
