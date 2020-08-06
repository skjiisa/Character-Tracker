//
//  PreferencesForm.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/6/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct PreferencesForm: View {
    
    // Replace with AppStorage when updating for SwiftUI 2 / iOS 14
    @Binding private var backticks: Bool
    
    init() {
        _backticks = Binding<Bool>(get: {
            UserDefaults.standard.bool(forKey: "jsonExportBackticks")
        }) { newValue in
            UserDefaults.standard.set(newValue, forKey: "jsonExportBackticks")
        }
    }
    
    var body: some View {
        Form {
            Toggle(isOn: $backticks) {
                Text("Include triple backticks when exporting JSON text")
            }
        }
        .navigationBarTitle("Preferences")
    }
}

struct PreferencesForm_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesForm()
    }
}
