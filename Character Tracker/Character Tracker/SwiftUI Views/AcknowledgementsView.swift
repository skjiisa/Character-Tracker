//
//  AcknowledgementsView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct AcknowledgementsView: View {
    
    func linkButton(title: String, url: String) -> some View {
        Button(title) {
            guard let url = URL(string: url) else { return }
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Images")) {
                Text("Images included in app provided by UESP under the Attribution-ShareAlike 2.5 License.")
                // These can be replaced by Links when upgrading to iOS 14
                linkButton(title: "UESP Copyright Policy", url: "https://en.uesp.net/wiki/UESPWiki:Copyright_and_Ownership")
                linkButton(title: "Attribution-ShareAlike 2.5 License", url: "https://creativecommons.org/licenses/by-sa/2.5/")
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Acknowledgements")
    }
}

struct AcknowledgementsView_Previews: PreviewProvider {
    static var previews: some View {
        AcknowledgementsView()
    }
}
