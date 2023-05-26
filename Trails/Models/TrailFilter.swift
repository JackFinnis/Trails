//
//  TrailFilter.swift
//  Trails
//
//  Created by Jack Finnis on 21/05/2023.
//

import Foundation

enum TrailFilter: Hashable {
    static let allCases = [TrailFilter.completed, .favourite] + TrailCountry.allCases.map { .country($0) }
    
    case completed
    case favourite
    case country(TrailCountry)
    
    var name: String {
        switch self {
        case .completed:
            return "Completed"
        case .favourite:
            return "Saved"
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
        default: return nil
        }
    }
}
