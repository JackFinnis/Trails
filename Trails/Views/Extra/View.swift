//
//  View.swift
//  Ecommunity
//
//  Created by Jack Finnis on 16/01/2022.
//

import SwiftUI

struct Background: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var background: Material { colorScheme == .light ? .regularMaterial : .thickMaterial }
    
    func body(content: Content) -> some View {
        content
            .background(background)
            .cornerRadius(12)
            .compositingGroup()
            .shadow(color: Color(.systemFill), radius: 5)
    }
}

struct Dismissible: ViewModifier {
    @EnvironmentObject var vm: ViewModel
    @State var offset = 0.0
    
    let edge: VerticalEdge
    let onDismiss: () -> Void
    
    init(edge: VerticalEdge, onDismiss: @escaping () -> Void) {
        self.edge = edge
        self.onDismiss = onDismiss
    }
    
    func body(content: Content) -> some View {
        let distance = vm.expand ? 200.0 : 100.0
        content
            .offset(x: 0, y: offset)
            .opacity((distance - (offset * (edge == .top ? -1 : 1)))/distance)
            .simultaneousGesture(DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 && edge == .bottom || value.translation.height < 0 && edge == .top {
                        offset = value.translation.height
                    } else {
                        offset = sqrt(value.translation.height.magnitude) * (value.translation.height.sign == .plus ? 1 : -1)
                    }
                }
                .onEnded { value in
                    if (value.predictedEndTranslation.height > distance/2 && edge == .bottom) || (value.predictedEndTranslation.height < -distance/2 && edge == .top) {
                        onDismiss()
                        offset = 0
                    } else {
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                }
            )
    }
}

extension View {
    func materialBackground() -> some View {
        modifier(Background())
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ applyModifier: Bool = true, @ViewBuilder content: (Self) -> Content) -> some View {
        if applyModifier {
            content(self)
        } else {
            self
        }
    }
    
    func iconFont() -> some View {
        font(.system(size: SIZE/2))
    }
    
    func horizontallyCentred() -> some View {
        HStack {
            Spacer(minLength: 0)
            self
            Spacer(minLength: 0)
        }
    }
    
    func bigButton() -> some View {
        self
            .font(.body.bold())
            .padding()
            .horizontallyCentred()
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(15)
    }
    
    func dismissible(edge: VerticalEdge, onDismiss: @escaping () -> Void) -> some View {
        modifier(Dismissible(edge: edge, onDismiss: onDismiss))
    }
    
    func squareButton() -> some View {
        self
            .iconFont()
            .frame(width: SIZE, height: SIZE)
    }
    
    func detectSize(_ size: Binding<CGSize>) -> some View {
        modifier(SizeDetector(size: size))
    }
}

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
