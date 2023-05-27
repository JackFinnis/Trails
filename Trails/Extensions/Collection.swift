//
//  Collection.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
    
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}
