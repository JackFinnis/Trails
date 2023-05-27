//
//  TrailFilter.swift
//  Trails
//
//  Created by Jack Finnis on 21/05/2023.
//

import Foundation

enum TrailFilter: Hashable {
    static let allCases = [TrailFilter.completed, .favourite, .cycleway] + TrailCountry.allCases.map { .country($0) }
    
    case completed
    case favourite
    case cycleway
    case country(TrailCountry)
    
    var name: String {
        switch self {
        case .completed:
            return "Completed"
        case .favourite:
            return "Saved"
        case .cycleway:
            return "Cycleways"
        case .country(let country):
            return country.rawValue
        }
    }
    
    var systemName: String? {
        switch self {
        case .completed:
            return "checkmark.circle"
        case .favourite:
            return "bookmark"
        case .cycleway:
            return "bicycle"
        case .country(_):
            return nil
        }
    }
}
