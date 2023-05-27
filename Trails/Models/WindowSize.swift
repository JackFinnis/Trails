//
//  WindowSize.swift
//  Trails
//
//  Created by Jack Finnis on 27/05/2023.
//

import Foundation

enum WindowSize: CGFloat, CaseIterable {
    case large
    case regular
    case compact
    
    var minWindowWidth: CGFloat {
        switch self {
        case .compact:
            return 0
        case .regular:
            return 500
        case .large:
            return 1100
        }
    }
    
    var maxSheetWidth: CGFloat {
        switch self {
        case .compact:
            return .infinity
        case .regular:
            return 320
        case .large:
            return 380
        }
    }
    
    init(_ size: CGSize) {
        for windowSize in WindowSize.allCases where size.width > windowSize.minWindowWidth {
            self = windowSize
            return
        }
        self = .compact
    }
}
