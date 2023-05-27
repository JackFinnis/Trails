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
    
    func equalTo(_ other: Double, to places: Int) -> Bool {
        rounded(to: places) == other.rounded(to: places)
    }
    
    func rounded(to places: Int) -> Double {
        let shift = pow(10, Double(places))
        return (self * shift).rounded() / shift
    }
}
