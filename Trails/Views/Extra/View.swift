//
//  View.swift
//  Ecommunity
//
//  Created by Jack Finnis on 16/01/2022.
//

import SwiftUI

struct Dismissible: ViewModifier {
    @State var offset = 0.0
    
    let edge: VerticalEdge
    let dismiss: () -> Void
    
    init(edge: VerticalEdge, dismiss: @escaping () -> Void) {
        self.edge = edge
        self.dismiss = dismiss
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: 0, y: offset)
            .opacity((100 - (offset * (edge == .top ? -1 : 1)))/100)
            .simultaneousGesture(DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 && edge == .bottom || value.translation.height < 0 && edge == .top {
                        offset = value.translation.height
                    } else {
                        offset = sqrt(value.translation.height.magnitude) * (value.translation.height.sign == .plus ? 1 : -1)
                    }
                }
                .onEnded { value in
                    if (value.predictedEndTranslation.height > 50 && edge == .bottom) || (value.predictedEndTranslation.height < -50 && edge == .top) {
                        dismiss()
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
    func blurBackground(opacity: CGFloat) -> some View {
        self.background(.thickMaterial, ignoresSafeAreaEdges: .all)
            .continuousRadius(10)
            .compositingGroup()
            .shadow(color: Color.black.opacity(opacity), radius: 5)
    }
    
    func horizontallyCentred() -> some View {
        HStack {
            Spacer(minLength: 0)
            self
            Spacer(minLength: 0)
        }
    }
    
    func squareButton() -> some View {
        self.font(.icon)
            .frame(width: SIZE, height: SIZE)
    }
    
    func continuousRadius(_ cornerRadius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    func bigButton() -> some View {
        self
            .font(.headline)
            .padding()
            .horizontallyCentred()
            .foregroundColor(.white)
            .background(Color.accentColor)
            .continuousRadius(16)
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ applyModifier: Bool = true, @ViewBuilder content: (Self) -> Content) -> some View {
        if applyModifier {
            content(self)
        } else {
            self
        }
    }
    
    func dismissible(edge: VerticalEdge, dismiss: @escaping () -> Void) -> some View {
        modifier(Dismissible(edge: edge, dismiss: dismiss))
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
