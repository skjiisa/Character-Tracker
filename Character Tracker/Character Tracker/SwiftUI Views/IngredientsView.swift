//
//  IngredientsView.swift
//  Character Tracker
//
//  Created by Isaac Lyons on 8/27/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct IngredientsView: View {
    @FetchRequest(entity: Ingredient.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]) var ingredients: FetchedResults<Ingredient>
    
    var didSelect: (Ingredient) -> Void
    
    init(didSelect: @escaping (Ingredient) -> Void = {_ in}) {
        self.didSelect = didSelect
    }
    
    var body: some View {
        List {
            ForEach(ingredients, id: \.self) { ingredient in
                Button(action: {
                    self.didSelect(ingredient)
                }) {
                    Text(ingredient.name ?? "Unknown ingredient")
                }
                .foregroundColor(.primary)
            }
        }
        .navigationBarTitle("Ingredients")
    }
}

struct IngredientsView_Previews: PreviewProvider {
    static var previews: some View {
        IngredientsView()
    }
}
