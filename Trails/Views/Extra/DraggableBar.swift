//
//  DraggableBar.swift
//  Change
//
//  Created by Jack Finnis on 29/10/2022.
//

import SwiftUI

struct DraggableBar: View {
    var body: some View {
        Rectangle()
            .frame(width: 36, height: 5)
            .foregroundColor(Color(.placeholderText))
            .clipShape(Capsule())
    }
}

struct DraggableTitle: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let title: String
    
    init(_ title: String = "") {
        self.title = title
    }
    
    var body: some View {
        if verticalSizeClass == .compact {
            Text(title)
                .font(.headline)
                .fixedSize()
        } else {
            VStack(spacing: 0) {
                DraggableBar()
                Spacer()
            }
            .frame(height: 45)
            .overlay {
                Text(title)
                    .font(.headline)
                    .fixedSize()
            }
        }
    }
}
