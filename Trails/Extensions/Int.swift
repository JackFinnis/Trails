//
//  Int.swift
//  Trails
//
//  Created by Jack Finnis on 18/04/2023.
//

import Foundation

extension Int {
    func formatted(singular: String) -> String {
        "\(self == 0 ? "No" : String(self)) \(singular)\(self == 1 ? "" : "s")"
    }
}
