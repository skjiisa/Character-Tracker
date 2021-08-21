//
//  AcknowledgementsView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 10/3/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct AcknowledgementsView: View {
    
    private var characterTrackerAcknowledgement = Acknowledgement(
        name: "BSD 2-Clause License",
        copyright: "2020, Isaac Lyons",
        link: nil,
        license: .bsd2)
    
    private var acknowledgements = [
        Acknowledgement(name: "ActionOver", copyright: "2020 Andrea Miotto", link: "https://github.com/AndreaMiotto/ActionOver", license: .mit),
        Acknowledgement(name: "AlertToast", copyright: "2021 Elai Zuberman", link: "https://github.com/elai950/AlertToast", license: .mit),
        Acknowledgement(name: "EFQRCode", copyright: "2017-2021 EyreFree", link: "https://github.com/EFPrefix/EFQRCode", license: .mit),
        Acknowledgement(name: "QRCodeSwift", copyright: "2017-2020 Zhiyu Zhu", link: "https://github.com/ApolloZhu/swift_qrcodejs", license: .mit),
        Acknowledgement(name: "Introspect for SwiftUI", copyright: "2019 Timber Software", link: "https://github.com/siteline/SwiftUI-Introspect", license: .mit),
        Acknowledgement(name: "Pluralize.swift", copyright: "2014 Joshua Arvin Lat", link: "https://github.com/joshualat/Pluralize.swift", license: .mit),
        Acknowledgement(name: "SDWebImage", copyright: "2009-2020 Olivier Poitrey", link: "https://github.com/SDWebImage/SDWebImage", license: .mit),
        Acknowledgement(name: "SDWebImageSwiftUI", copyright: "2019 lizhuoli1126@126.com", link: "https://github.com/SDWebImage/SDWebImageSwiftUI", license: .mit),
        Acknowledgement(name: "SwiftyJSON", copyright: "2017 Ruoyu Fu", link: "https://github.com/SwiftyJSON/SwiftyJSON", license: .mit)
    ]
    
    @State private var selection: Acknowledgement?
    @State private var listID = UUID()
    
    var body: some View {
        Form {
            Section(header: Text("Images")) {
                Text("Images included in app provided by UESP under the Attribution-ShareAlike 2.5 License.")
                LinkButton(destination: URL(string: "https://en.uesp.net/wiki/UESPWiki:Copyright_and_Ownership")!, title: "UESP Copyright Policy")
                LinkButton(destination: URL(string: "https://creativecommons.org/licenses/by-sa/2.5/")!, title: "Attribution-ShareAlike 2.5 License")
            }
            
            Section(header: Text("License")) {
                Text("This app is open-source software.")
                AcknowledgementLink(characterTrackerAcknowledgement, selection: $selection)
            }
            
            Section(header: Text("Libraries")) {
                ForEach(acknowledgements, id: \.self) { acknowledgement in
                    AcknowledgementLink(acknowledgement, selection: $selection)
                }
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .navigationBarTitle("Acknowledgements")
        // Workaround for buggy NavigationLink behavior in iOS 14
        .id(listID)
        .onAppear {
            if selection != nil {
                selection = nil
                listID = UUID()
            }
        }
    }
}

struct AcknowledgementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AcknowledgementsView()
        }
    }
}
