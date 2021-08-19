//
//  PageView.swift
//  Character Tracker
//
//  Created by Elaine Lyons on 8/18/21.
//

import SwiftUI

extension Animation {
    static var push: Animation {
        .timingCurve(187/677.5, 1 - 30.5/485.5, 193/677.5, 1 - -3.5/485.5, duration: 0.5)
    }
}

struct PageView<Content: View>: View {
    
    var pageCount: Int
    @Binding var currentIndex: Int
    @ViewBuilder var content: Content
    
    @GestureState private var translation: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                content.frame(width: geo.size.width)
            }
            .frame(width: geo.size.width, alignment: .leading)
            .offset(x: -CGFloat(currentIndex) * geo.size.width + translation)
            // I know that this .animation is what's causing the swiping to be laggy,
            // but I can't for the life of me figure out another solution that works.
            // I've tried resetting translation and currentIndex in a withAnimation,
            // and I've tried having a dragging boolean property as seen in Tickmate,
            // but for some reason that doesn't work here when it does in Tickmate.
            .animation(.push)
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                    state = (currentIndex == 0 && value.translation.width > 0)
                        || (currentIndex == pageCount - 1 && value.translation.width < 0)
                        ? value.translation.width / 3
                        : value.translation.width
                }
                .onEnded { value in
                    let offset = value.predictedEndTranslation.width / geo.size.width
                    let newIndex = Int((CGFloat(currentIndex) - offset).rounded())
                    let adjacentIndex = newIndex > currentIndex
                        ? min(newIndex, currentIndex + 1)
                        : newIndex < currentIndex
                        ? max(newIndex, currentIndex - 1)
                        : currentIndex
                    currentIndex = min(max(adjacentIndex, 0), pageCount - 1)
                }
            )
        }
    }
}

struct PageView_Previews: PreviewProvider {
    static var previews: some View {
        PageView(pageCount: 2, currentIndex: .constant(0)) {
            Text("One")
            Text("Two")
        }
    }
}
