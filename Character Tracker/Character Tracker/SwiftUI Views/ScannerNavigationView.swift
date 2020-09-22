//
//  ScannerNavigationView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/9/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ScannerNavigationView: View {
    @Binding var showing: Bool
    @Binding var alert: Alert?
    
    var cancelButton: some View {
        Button("Cancel") {
            self.showing = false
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
            ScannerView(showing: $showing, alert: $alert)
                .navigationBarTitle("Scan QR Code", displayMode: .inline)
                .navigationBarItems(leading: cancelButton, trailing: infoButton)
        }
    }
}

struct ScannerNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerNavigationView(showing: .constant(true), alert: .constant(nil))
    }
}
