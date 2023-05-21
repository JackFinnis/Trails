//
//  Array.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import Foundation
import MapKit

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
    func sum() -> Element {
        reduce(Element.init(0), +)
    }
}

extension Array where Element: Equatable {
    mutating func removeAll(_ value: Element) {
        removeAll { $0 == value }
    }
}

extension Array where Element: Sequence {
    func concat() -> [Element.Element] {
        flatMap { $0 }
    }
}

extension Array where Element == CLLocationCoordinate2D {
    func metres() -> Double {
        map(\.location).metres()
    }
}

extension Array where Element: MKOverlay {
    var rect: MKMapRect {
        reduce(.null) { $0.union($1.boundingMapRect) }
    }
}
