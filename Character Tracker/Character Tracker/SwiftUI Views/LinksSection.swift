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
    var delete: ([ExternalLink]) -> Void
    
    @State private var changesToSave = false
        
    init(predicate: NSPredicate, editMode: Binding<Bool>, onCreate: @escaping () -> Void, onDelete: @escaping ([ExternalLink]) -> Void) {
        linksFetchRequest = FetchRequest(
            entity: ExternalLink.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \ExternalLink.name, ascending: true)],
            predicate: predicate,
            animation: .default)
        _editMode = editMode
        create = onCreate
        delete = onDelete
    }
    
    init(mod: Mod, editMode: Binding<Bool>, onCreate: @escaping () -> Void, onDelete: @escaping ([ExternalLink]) -> Void) {
        self.init(predicate: NSPredicate(format: "%@ IN mods", mod), editMode: editMode, onCreate: onCreate, onDelete: onDelete)
    }
    
    init(module: Module, onCreate: @escaping () -> Void, onDelete: @escaping ([ExternalLink]) -> Void) {
        self.init(predicate: NSPredicate(format: "%@ IN modules", module), editMode: .constant(true), onCreate: onCreate, onDelete: onDelete)
    }
    
    var body: some View {
        if !links.isEmpty || editMode {
            Section(header: Text(editMode ? "Links" : "")) {
                ForEach(links) { link in
                    LinkItem(link: link, editMode: $editMode, changesToSave: $changesToSave)
                }
                .onDelete { indexSet in
                    delete(indexSet.map { links[$0] })
                    changesToSave = true
                }
                
                if editMode {
                    Button("Add link") {
                        create()
                        changesToSave = true
                    }
                }
            }
            .onDisappear {
                if changesToSave {
                    CoreDataStack.shared.save(context: moc, source: "LinksSection onDisappear")
                    changesToSave = false
                }
            }
        }
    }
}

struct LinkItem: View {
    @ObservedObject var link: ExternalLink
    @Binding var editMode: Bool
    @Binding var changesToSave: Bool
    
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
                        changesToSave = true
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
                    HStack {
                        Text(link.name ??? link.id.wrappedString)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
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
