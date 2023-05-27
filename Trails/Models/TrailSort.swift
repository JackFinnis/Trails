//
//  TrailSort.swift
//  Trails
//
//  Created by Jack Finnis on 21/05/2023.
//

import Foundation

enum TrailSort: String, CaseIterable, Codable {
    case name = "Name"
    case distance = "Length"
    case ascent = "Ascent"
    case completed = "Completed"
}
