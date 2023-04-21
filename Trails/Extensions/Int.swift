//
//  Int.swift
//  Trails
//
//  Created by Jack Finnis on 18/04/2023.
//

import Foundation

extension Int {
    func formatted(word: String) -> String {
        "\(self) \(word)\(self == 1 ? "" : "s")"
    }
}
