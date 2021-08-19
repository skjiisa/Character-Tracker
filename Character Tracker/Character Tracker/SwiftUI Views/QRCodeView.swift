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

struct QRCodes: Identifiable {
    var id: UUID
    var codes: [CGImage]
    
    init?(_ codes: [CGImage]) {
        guard !codes.isEmpty else { return nil }
        self.codes = codes
        id = UUID()
    }
}

struct QRCodeView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var shareURL: URL?
    @State private var showingShareSheet: Bool = false
    @State private var selection: Int = 0
    
    var name: String?
    var qrCodes: QRCodes
    var delegate: SwiftUIModalDelegate? = nil
    
    init(name: String?, qrCodes: QRCodes, delegate: SwiftUIModalDelegate? = nil) {
        self.name = name
        self.qrCodes = qrCodes
        self.delegate = delegate
    }
    
    var shareButton: some View {
        Button {
            guard let url = PortController.shared.saveTempQRCodes(qrCodes.codes)?.first else { return }
            shareURL = url
            showingShareSheet = true
        } label: {
            if #available(iOS 14.0, *) {
                // Label improves accessibility by having a title.
                Label("Share QR code", systemImage: "square.and.arrow.up")
                    .labelStyle(IconOnlyLabelStyle())
            } else {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
            }
        }
    }
    
    var shareAllButton: some View {
        Button {
            guard let urls = PortController.shared.saveTempQRCodes(qrCodes.codes) else { return }
            //TODO: Shore URLs
            showingShareSheet = true
        } label: {
            if #available(iOS 14.0, *) {
                // Label improves accessibility by having a title.
                Label("Share all QR codes", systemImage: "square.and.arrow.up.on.square")
                    .labelStyle(IconOnlyLabelStyle())
            } else {
                Image(systemName: "square.and.arrow.up.on.square")
                    .imageScale(.large)
            }
        }
    }
    
    var doneButton: some View {
        Button("Done") {
            self.delegate?.dismiss()
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    @ViewBuilder
    var qrCodesList: some View {
        if #available(iOS 14.0, *) {
            TabView(selection: $selection) {
                ForEach(0..<qrCodes.codes.count) { index in
                    Image(decorative: qrCodes.codes[index], scale: 1)
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
        } else {
            //TODO: iOS 13 solution
        }
    }
    
    var body: some View {
        if shareURL != nil {
            // If we don't have anything observing shareURL,
            // it won't update, meaning it'll be nil when
            // we try accessing it for the Share Sheet.
            EmptyView()
        }
        qrCodesList
            .navigationBarTitle("\(name ?? "QR Code")", displayMode: .inline)
            .navigationBarItems(leading: shareButton, trailing: doneButton)
            .sheet(isPresented: $showingShareSheet) {
                PortController.shared.clearFilesFromTempDirectory()
            } content: {
                if shareURL != nil {
                    ShareSheet(activityItems: [shareURL!])
                }
            }
    }
}
