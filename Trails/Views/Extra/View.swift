//
//  View.swift
//  Ecommunity
//
//  Created by Jack Finnis on 16/01/2022.
//

import SwiftUI

extension View {
    func blurBackground(prominentShadow: Bool, corners: UIRectCorner = .allCorners) -> some View {
        self.background(.thickMaterial)
            .continuousRadius(10, corners: corners)
            .compositingGroup()
            .shadow(color: Color.black.opacity(prominentShadow ? 0.2 : 0.1), radius: 5)
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
            .frame(width: Constants.size, height: Constants.size)
    }
    
    func continuousRadius(_ radius: CGFloat, corners: UIRectCorner = .allCorners) -> some View {
        clipShape(RoundedCorners(radius: radius, corners: corners))
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
    
    func onDismiss(onDismiss: @escaping () -> Void) -> some View {
        modifier(OnDismiss(onDismiss: onDismiss))
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ applyModifier: Bool = true, @ViewBuilder content: (Self) -> Content) -> some View {
        if applyModifier {
            content(self)
        } else {
            self
        }
    }
}

struct RoundedCorners: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct OnDismiss: ViewModifier {
    @State var offset = 0.0
    
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    let translation = gesture.translation.height
                    if translation > 0 {
                        offset = translation
                    } else {
                        offset = -sqrt(-translation)
                    }
                }
                .onEnded { value in
                    if value.predictedEndTranslation.height > 20 {
                        onDismiss()
                    }
                    withAnimation {
                        offset = 0
                    }
                }
            )
    }
}
