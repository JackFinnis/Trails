//
//  Double.swift
//  Paddle
//
//  Created by Jack Finnis on 25/09/2022.
//

import Foundation

extension Double {
    func formattedInterval() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? ""
    }
    
    func equalTo(_ other: Double, to decimalPlaces: Int) -> Bool {
        rounded(to: decimalPlaces) == other.rounded(to: decimalPlaces)
    }
    
    func rounded(to decimalPlaces: Int) -> Decimal {
        var initialDecimal = Decimal(self)
        var roundedDecimal = Decimal()
        NSDecimalRound(&roundedDecimal, &initialDecimal, decimalPlaces, .plain)
        return roundedDecimal
    }
}
