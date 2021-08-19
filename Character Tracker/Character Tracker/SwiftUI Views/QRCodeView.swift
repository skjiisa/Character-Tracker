//
//  QRCodeView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/6/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

//MARK: SwiftUIModalDelegate

protocol SwiftUIModalDelegate {
    func dismiss()
}

//MARK: QRCodes

struct QRCodes: Identifiable {
    var id: UUID
    var codes: [CGImage]
    var count: Int {
        codes.count
    }
    
    init?(_ codes: [CGImage]) {
        guard !codes.isEmpty else { return nil }
        self.codes = codes
        id = UUID()
    }
}

//MARK: URLs

struct URLs: Identifiable {
    var id: UUID
    var urls: [URL]
    
    init?(_ urls: [URL]) {
        guard !urls.isEmpty else { return nil }
        self.urls = urls
        id = UUID()
    }
    
    init(url: URL) {
        urls = [url]
        id = UUID()
    }
}

//MARK: QRCodeView

struct QRCodeView: View {
    //MARK: Properties
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var shareURLs: URLs?
    @State private var selection: Int = 0
    
    var name: String?
    var qrCodes: QRCodes
    var delegate: SwiftUIModalDelegate? = nil
    
    init(name: String?, qrCodes: QRCodes, delegate: SwiftUIModalDelegate? = nil) {
        self.name = name
        self.qrCodes = qrCodes
        self.delegate = delegate
    }
    
    //MARK: Views
    
    var shareButton: some View {
        Button {
            guard let url = PortController.shared.saveTempQRCode(qrCodes.codes[selection], index: selection) else { return }
            shareURLs = URLs(url: url)
        } label: {
            if #available(iOS 14.0, *) {
                // Label improves accessibility by having a title.
                Label("Share QR code", systemImage: "square.and.arrow.up")
                    .labelStyle(IconOnlyLabelStyle())
            } else {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    var shareAllButton: some View {
        Button {
            guard let urls = PortController.shared.saveTempQRCodes(qrCodes.codes) else { return }
            shareURLs = URLs(urls)
        } label: {
            if #available(iOS 14.0, *) {
                // Label improves accessibility by having a title.
                Label("Share all QR codes", systemImage: "square.and.arrow.up.on.square")
                    .labelStyle(IconOnlyLabelStyle())
            } else {
                Image(systemName: "square.and.arrow.up.on.square")
            }
        }
    }
    
    var shareBarButtons: some View {
        HStack {
            shareButton
            if qrCodes.count > 1 {
                shareAllButton
                    .padding(.leading)
            }
        }
        .font(.body)
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
                ForEach(0..<qrCodes.count) { index in
                    Image(decorative: qrCodes.codes[index], scale: 1)
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .navigationBarTitle("\(name ?? "QR Code")", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    doneButton
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    shareButton
                    if qrCodes.count > 1 {
                        Spacer()
                        Text("\(selection + 1)/\(qrCodes.count)")
                            .font(.body.monospacedDigit())
                        Spacer()
                        shareAllButton
                    }
                }
            }
        } else {
            PageView(pageCount: qrCodes.count, currentIndex: $selection) {
                ForEach(0..<qrCodes.count) { index in
                    VStack {
                        Spacer()
                        Image(decorative: qrCodes.codes[index], scale: 1)
                            .resizable()
                            .scaledToFit()
                        Spacer()
                    }
                }
            }
            .navigationBarTitle(qrCodes.count > 1 ? "\(selection + 1)/\(qrCodes.count)" : "\(name ?? "QR Code")", displayMode: .inline)
            .navigationBarItems(leading: shareBarButtons, trailing: doneButton)
        }
    }
    
    //MARK: Body
    
    var body: some View {
        if shareURLs != nil {
            // If we don't have anything observing shareURL,
            // it won't update, meaning it'll be nil when
            // we try accessing it for the Share Sheet.
            EmptyView()
        }
        qrCodesList
            .sheet(item: $shareURLs) {
                PortController.shared.clearFilesFromTempDirectory()
            } content: { urls in
                ShareSheet(activityItems: urls.urls)
            }
    }
}
