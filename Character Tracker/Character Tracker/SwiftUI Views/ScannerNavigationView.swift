//
//  ScannerNavigationView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/9/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI
import AlertToast

struct ToastItem {
    var showing = false
    var title: String?
    var subtitle: String?
    var completion: (() -> Void)?
    
    mutating func show() {
        showing = true
    }
}

struct ScannerNavigationView: View {
    
    @Binding var showing: Bool
    @Binding var alert: Alert?
    
    @State private var toast = ToastItem()
    
    var cancelButton: some View {
        Button("Cancel") {
            showing = false
        }
    }
    
    var infoButton: some View {
        NavigationLink(destination: ScannerInfoView()) {
            Image(systemName: "info.circle")
                .imageScale(.large)
        }
    }
    
    var body: some View {
        NavigationView {
            ScannerView(showing: $showing, alert: $alert, toast: $toast)
                .navigationBarTitle("Scan QR Code", displayMode: .inline)
                .navigationBarItems(leading: cancelButton, trailing: infoButton)
                .toast(isPresenting: $toast.showing, duration: 2, tapToDismiss: true) {
                    AlertToast(displayMode: .alert, type: .regular, title: toast.title, subTitle: toast.subtitle, custom: .custom(titleFont: .largeTitle, subTitleFont: .title))
                } completion: {
                    // Resume scanning
                    print("Resume scanning")
                    toast.completion?()
                }

        }
    }
}

struct ScannerNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerNavigationView(showing: .constant(true), alert: .constant(nil))
    }
}
