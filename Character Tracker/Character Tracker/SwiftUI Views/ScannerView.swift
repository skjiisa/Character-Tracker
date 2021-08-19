//
//  ScannerView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/31/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI
import SwiftyJSON

struct ScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ScannerViewController
    
    @Binding var showing: Bool
    @Binding var alert: Alert?
    
    var dispatchGroup = DispatchGroup()
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerVC = ScannerViewController()
        scannerVC.delegate = context.coordinator
        
        // If a code is scanned too fast, it will try to dismiss before it's finished being presented.
        // Since it's being presented with SwiftUI, we don't have a completion parameter,
        // so here instead it's just waiting 1 second after being presented before it'll dismiss.
        // I tried shorter amounts of time and this seems like the right amount.
        dispatchGroup.enter()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.dispatchGroup.leave()
        }
        
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    class Coordinator: ScannerViewControllerDelegate, MultiQRDelegate {
        var parent: ScannerView
        var multiQR: MultiQR?
        
        init(_ parent: ScannerView) {
            self.parent = parent
        }
        
        func found(code: String) {
            let json = JSON(parseJSON: code)
            // Confusingly, json's null value being nil means that the JSON is not null.
            if json.null == nil {
                // This code is JSON
                self.import(json: json)
            } else {
                // This code is not JSON. Try to load it as a MultiQR
                if let multiQR = multiQR {
                    // If this is the last code, MultiQR will call its delegate's
                    // `import` function, in this case its delegate being this.
                    multiQR.scan(code: code)
                } else {
                    multiQR = MultiQR(code: code, delegate: self)
                }
            }
        }
        
        func `import`(json: JSON) {
            print("JSON import successful!", json)
            
            let context = CoreDataStack.shared.container.newBackgroundContext()
            
            context.performAndWait {
                let importedNames = PortController.shared.import(json: json, context: context)
                
                let save = Alert.Button.default(Text("Save")) {
                    CoreDataStack.shared.save(context: context)
                }
                
                let alert = Alert(title: Text("Imported objects"),
                                  message: Text(importedNames.joined(separator: ", ")),
                                  primaryButton: save,
                                  secondaryButton: Alert.Button.cancel())
                
                self.parent.dispatchGroup.notify(queue: .main) {
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
