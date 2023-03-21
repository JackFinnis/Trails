//
//  Double.swift
//  Paddle
//
//  Created by Jack Finnis on 25/09/2022.
//

import Foundation

extension Double {
    var formattedInterval: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? ""
    }
    
    func equalTo(_ other: Double, to decimalPlaces: Int) -> Bool {
        rounded(to: decimalPlaces) == other.rounded(to: decimalPlaces)
    }
    
    func rounded(to decimalPlaces: Int) -> Decimal {
        var original = Decimal(self)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &original, decimalPlaces, .plain)
        return rounded
    }
}
