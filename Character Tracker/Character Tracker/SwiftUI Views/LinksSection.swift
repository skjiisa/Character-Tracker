//
//  LinksSection.swift
//  Character Tracker
//
//  Created by Elaine Lyons on 7/21/21.
//

import SwiftUI
import Coalescing_Operators

struct LinksSection: View {
    @Environment(\.managedObjectContext) var moc
    
    var linksFetchRequest: FetchRequest<ExternalLink>
    var links: FetchedResults<ExternalLink> {
        linksFetchRequest.wrappedValue
    }
    
    @Binding var editMode: Bool
    var create: () -> Void
        
    init(predicate: NSPredicate, editMode: Binding<Bool>, onCreate: @escaping () -> Void) {
        linksFetchRequest = FetchRequest(
            entity: ExternalLink.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \ExternalLink.name, ascending: true)],
            predicate: predicate,
            animation: .default)
        _editMode = editMode
        create = onCreate
    }
    
    init(mod: Mod, editMode: Binding<Bool>, onCreate: @escaping () -> Void) {
        self.init(predicate: NSPredicate(format: "%@ IN mods", mod), editMode: editMode, onCreate: onCreate)
    }
    
    init(module: Module, onCreate: @escaping () -> Void) {
        self.init(predicate: NSPredicate(format: "%@ IN modules", module), editMode: .constant(true), onCreate: onCreate)
    }
    
    var body: some View {
        if !links.isEmpty || editMode {
            Section(header: Text(editMode ? "Links" : "")) {
                ForEach(links) { link in
                    LinkItem(link: link, editMode: $editMode)
                }
                .onDelete { indexSet in
                    indexSet.map { links[$0] }.forEach(moc.delete)
                }
                
                if editMode {
                    Button("Add link") {
                        create()
                    }
                }
            }
        }
    }
}

struct LinkItem: View {
    @ObservedObject var link: ExternalLink
    @Binding var editMode: Bool
    
    @State private var name = ""
    @State private var url = ""
    @State private var editing = false
    
    var body: some View {
        HStack {
            if editing {
                HStack {
                    TextField("Name", text: $name)
                    Spacer()
                    Button("Done") {
                        link.name = name
                        link.id = url
                        withAnimation {
                            editing = false
                        }
                    }
                }
                .onAppear {
                    name = link.wrappedName
                    url = link.id.wrappedString
                }
            } else {
                Button {
                    if editMode {
                        withAnimation {
                            editing = true
                        }
                    } else if let url = URL(string: link.id.wrappedString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(link.name ??? link.id.wrappedString)
                }
            }
        }
        
        if editing {
            TextField("URL", text: $url)
                .disableAutocorrection(true)
                .keyboardType(.URL)
        }
    }
}
