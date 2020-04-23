//
//  CharacterIngredientsView.swift
//  Character Tracker Watch Extension
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import SwiftUI

struct CharacterIngredientsView: View {
    var character: CharacterRepresentation
    
    var body: some View {
        List {
            ForEach(character.moduleIngredients) { moduleRepresentation in
                Section(header: Text("\(moduleRepresentation.level > 0 ? "Level \(moduleRepresentation.level):" : "") \(moduleRepresentation.name)")) {
                    ForEach(moduleRepresentation.ingredients) { ingredientRepresentation in
                        HStack {
                            Text(ingredientRepresentation.name)
                            if ingredientRepresentation.quantity > 0 {
                                Spacer()
                                Text("\(ingredientRepresentation.quantity)")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CharacterIngredientsView_Previews: PreviewProvider {
    static var previews: some View {
        CharacterIngredientsView(character:
            CharacterRepresentation(name: "Ja'Zakajirr", modules: [
                ModuleRepresentation(name: "Leather Armor", ingredients: [
                IngredientRepresentation(name: "Leather Strips", quantity: 8),
                    IngredientRepresentation(name: "Leather", quantity: 9)
                ])
            ]))
    }
}
