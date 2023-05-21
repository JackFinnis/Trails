//
//  SizeDetector.swift
//  Trails
//
//  Created by Jack Finnis on 21/05/2023.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue = CGSize.zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct SizeDetector: ViewModifier {
    @Binding var size: CGSize

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    Color.clear.preference(key: SizePreferenceKey.self, value: geo.size)
                }
            }
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                size = newSize
            }
    }
}

extension View {
    func detectSize(_ size: Binding<CGSize>) -> some View {
        modifier(SizeDetector(size: size))
    }
}
