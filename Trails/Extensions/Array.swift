//
//  Array.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import Foundation

extension Array where Element: Comparable {
    mutating func removeAll(_ value: Element) {
        removeAll { $0 == value }
    }
}
