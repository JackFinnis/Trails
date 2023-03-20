//
//  Number.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import Foundation

protocol Number {
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    init(_ v: Int)
}

extension Double: Number {}
extension Int: Number {}

extension Array where Element: Number {
    var sum: Element {
        reduce(Element.init(0), +)
    }
}
