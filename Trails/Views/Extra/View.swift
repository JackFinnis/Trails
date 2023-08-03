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
            .shadow(prominent: prominentShadow)
    }
    
    func containerBackground(light: Bool) -> some View {
        modifier(ContainerBackground(light: light))
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
    
    func shadow(prominent: Bool = true) -> some View {
        shadow(color: Color.black.opacity(prominent ? 0.2 : 0.1), radius: 5)
    }
    
    func bigButton() -> some View {
        self
            .font(.headline)
            .padding()
            .horizontallyCentred()
            .foregroundColor(.white)
            .background(Color.accentColor)
            .continuousRadius(15)
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
    @GestureState var translation = 0.0
    
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .offset(y: translation)
            .animation(.sheet, value: translation == 0)
            .gesture(DragGesture(minimumDistance: 0)
                .updating($translation) { gesture, state, transaction in
                    let translation = gesture.translation.height
                    if translation > 0 {
                        state = translation
                    } else {
                        state = -sqrt(-translation)
                    }
                }
                .onEnded { value in
                    if value.predictedEndTranslation.height > 30 {
                        onDismiss()
                    }
                }
            )
    }
}

struct ContainerBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    let light: Bool
    
    func body(content: Content) -> some View {
        content.background {
            if light {
                Color(colorScheme == .light ? .white : .secondarySystemBackground)
            } else {
                Color(colorScheme == .light ? .tertiarySystemFill : .quaternarySystemFill)
            }
        }
    }
}
