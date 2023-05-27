//
//  WindowSize.swift
//  Trails
//
//  Created by Jack Finnis on 27/05/2023.
//

import Foundation

enum HorizontalSizeClass: CGFloat, CaseIterable {
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
        for sizeClass in HorizontalSizeClass.allCases where size.width > sizeClass.minWindowWidth {
            self = sizeClass
            return
        }
        self = .compact
    }
}

enum VerticalSizeClass: CGFloat, CaseIterable {
    case regular
    case compact
    
    var minWindowHeight: CGFloat {
        switch self {
        case .regular:
            return 800
        case .compact:
            return 0
        }
    }
    
    var mediumSheetDetent: CGFloat {
        switch self {
        case .regular:
            return 300
        case .compact:
            return 270
        }
    }
    
    init(_ size: CGSize) {
        for sizeClass in VerticalSizeClass.allCases where size.width > sizeClass.minWindowHeight {
            self = sizeClass
            return
        }
        self = .compact
    }
}
