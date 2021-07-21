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
        Form {
            Section(header: Text("Images")) {
                Text("Images included in app provided by UESP under the Attribution-ShareAlike 2.5 License.")
                // These can be replaced by Links when upgrading to iOS 14
                linkButton(title: "UESP Copyright Policy", url: "https://en.uesp.net/wiki/UESPWiki:Copyright_and_Ownership")
                linkButton(title: "Attribution-ShareAlike 2.5 License", url: "https://creativecommons.org/licenses/by-sa/2.5/")
            }
            
            Section(header: Text("License")) {
                Text("This app is open-source software.")
                NavigationLink("BSD 2-Clause License", destination: LicenseView())
            }
            
            Section(header: Text("Libraries")) {
                ForEach(LibraryView.Library.allCases, id: \.self) { library in
                    NavigationLink(library.name, destination: LibraryView(library: library))
                }
            }
        }
        .navigationBarTitle("Acknowledgements")
    }
}

fileprivate struct LicenseView: View {
    
    let licenseText =
"""
Copyright (c) 2020, Isaac Lyons
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""
    
    var body: some View {
        Form {
            Text(licenseText)
        }
        .navigationBarTitle("BSD 2-Clause License")
    }
}

fileprivate struct LibraryView: View {
    
    enum Library: CaseIterable {
        case swiftyJSON
        case pluralize
        case efqrcode
        case actionOver
        case sdWebImageSwiftUI
        
        var name: String {
            switch self {
            case .swiftyJSON:
                return "SwiftyJSON"
            case .pluralize:
                return "Pluralize.swift"
            case .efqrcode:
                return "EFQRCode"
            case .actionOver:
                return "ActionOver"
            case .sdWebImageSwiftUI:
                return "SDWebImageSwiftUI"
            }
        }
        
        var url: URL {
            switch self {
            case .swiftyJSON:
                return URL(string: "https://github.com/SwiftyJSON/SwiftyJSON")!
            case .pluralize:
                return URL(string: "https://github.com/joshualat/Pluralize.swift")!
            case .efqrcode:
                return URL(string: "https://github.com/EFPrefix/EFQRCode")!
            case .actionOver:
                return URL(string: "https://github.com/AndreaMiotto/ActionOver")!
            case .sdWebImageSwiftUI:
                return URL(string: "https://github.com/SDWebImage/SDWebImageSwiftUI")!
            }
        }
        
        var license: String {
            switch self {
            case .swiftyJSON:
                return Library.mit(copyright: "2017 Ruoyu Fu")
            case .pluralize:
                return Library.mit(copyright: "2014 Joshua Arvin Lat")
            case .efqrcode:
                return Library.mit(copyright: "2017 EyreFree")
            case .actionOver:
                return Library.mit(copyright: "2020 Andrea Miotto")
            case .sdWebImageSwiftUI:
                return Library.mit(copyright: "2019 lizhuoli1126@126.com")
            }
        }
        
        private static func mit(copyright: String) -> String {
"""
Copyright (c) \(copyright)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""
        }
    }
    
    var library: Library
    
    var body: some View {
        Form {
            Section {
                Button {
                    UIApplication.shared.open(library.url)
                } label: {
                    HStack {
                        Text(library.name)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
            }
            
            Section(header: Text("License")) {
                Text(library.license)
            }
        }
        .navigationBarTitle(library.name)
    }
}

struct AcknowledgementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            AcknowledgementsView()
        }
    }
}
