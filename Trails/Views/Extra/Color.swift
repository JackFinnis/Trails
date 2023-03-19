//
//  Color.swift
//  Trails
//
//  Created by Jack Finnis on 19/03/2023.
//

import SwiftUI

extension Color {
    static var background: Color {
        UITraitCollection.current.userInterfaceStyle == .light ? .white : .black
    }
}
