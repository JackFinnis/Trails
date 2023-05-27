//
//  CNPostalAddress.swift
//  Trails
//
//  Created by Jack Finnis on 27/05/2023.
//

import Foundation
import Contacts

extension CNPostalAddress {
    func formatted() -> String {
        CNPostalAddressFormatter().string(from: self)
    }
}
