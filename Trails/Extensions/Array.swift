//
//  Array.swift
//  Trails
//
//  Created by Jack Finnis on 20/03/2023.
//

import Foundation
import MapKit

extension Array {
    func every(_ n: Int) -> Self {
        guard n > 1 else { return Array(self) }
        return enumerated().compactMap { index, element in index % n == 0 ? element : nil }
    }
}

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

extension Array where Element: MKOverlay {
    var rect: MKMapRect {
        reduce(.null) { $0.union($1.boundingMapRect) }
    }
}

extension Array where Element == CLLocationCoordinate2D {
    func metres() -> Double {
        map(\.location).metres()
    }
}

extension Array where Element == CLLocation {
    func metres() -> Double {
        guard count >= 2 else { return 0 }
        var distance = Double.zero
        
        for i in 1..<count {
            distance += self[i].distance(from: self[i - 1])
        }
        return distance
    }
    
    func ascent() -> Double {
        guard count > 1 else { return 0 }
        var ascent = Double.zero
        
        for i in 1..<count {
            let delta = self[i].altitude - self[i - 1].altitude
            if delta > 0 {
                ascent += delta
            }
        }
        return ascent
    }
    
    func descent() -> Double {
        reversed().ascent()
    }
}
