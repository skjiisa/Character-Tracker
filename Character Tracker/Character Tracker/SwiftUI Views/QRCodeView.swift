//
//  QRCodeView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/6/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

protocol SwiftUIModalDelegate {
    func dismiss()
}

struct QRCodeView: View {
    
    @State private var shareURL: URL?
    @State private var showingShareSheet: Bool = false
    
    var name: String?
    var qrCode: CGImage
    var delegate: SwiftUIModalDelegate?
    
    var shareButton: some View {
        Button(action: {
            guard let url = PortController.shared.saveTempQRCode(cgImage: self.qrCode) else { return }
            self.shareURL = url
            self.showingShareSheet = true
        }) {
            Image.init(systemName: "square.and.arrow.up")
                .imageScale(.large)
        }
    }
    
    var doneButton: some View {
        Button("Done") {
            self.delegate?.dismiss()
        }
    }
    
    var body: some View {
        Image(decorative: qrCode, scale: 1)
            .resizable()
            .scaledToFit()
            .navigationBarTitle("\(name ?? "QR Code")", displayMode: .inline)
            .navigationBarItems(leading: shareButton, trailing: doneButton)
            .sheet(isPresented: $showingShareSheet) {
                if self.shareURL != nil {
                    ShareSheet(activityItems: [self.shareURL!])
                }
        }
    }
}
