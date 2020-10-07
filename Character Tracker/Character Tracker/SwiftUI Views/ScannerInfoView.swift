//
//  ScannerInfoView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 9/9/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct ScannerInfoView: View {
    
    enum Content: Hashable {
        case text(String)
        case link(title: String, url: String)
    }
    
    var content: [Content] = [
        .text("Here you can scan QR codes to import data into Character Tracker."),
        .text("You can generate QR codes from Modules or Mods you've added by tapping the \"Export\" button at the bottom of its detail page."),
        .text("An example QR Code can be found in the readme on GitHub."),
        .link(title: "Character Tracker on GitHub", url: "https://github.com/Isvvc/Character-Tracker"),
        .text("QR Codes can also be generated from Skyrim armor sets using xEdit Armor Export."),
        .link(title: "xEdit Armor Export on GitHub", url: "https://github.com/Isvvc/xEdit-Armor-Export")
    ]
    
    func contentItem(_ item: Content) -> some View {
        switch item {
        case .text(let text):
            return AnyView(Text(text))
                .padding()
        case .link(title: let title, url: let url):
            return AnyView(
                Button(title) {
                    guard let url = URL(string: url) else { return }
                    UIApplication.shared.open(url)
                })
                .padding(.bottom)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .padding()
                
                ForEach(content, id: \.self) { string in
                    self.contentItem(string)
                }
                .font(.body)
                .multilineTextAlignment(.center)
            }
        }
        .navigationBarTitle("QR Code Info", displayMode: .automatic)
    }
}

struct ScannerInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerInfoView()
    }
}
