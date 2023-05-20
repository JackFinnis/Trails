//
//  Array.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import Foundation

extension Array where Element: Equatable {
    mutating func removeAll(_ value: Element) {
        removeAll { $0 == value }
    }
}

extension Array where Element: Sequence {
    func concat() -> [Element.Element] where Element: Sequence {
        flatMap { $0 }
    }
}
