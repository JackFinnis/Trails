//
//  CLPlacemark.swift
//  Trails
//
//  Created by Jack Finnis on 26/03/2023.
//

import Contacts

extension CNPostalAddress {
    func formatted() -> String {
        CNPostalAddressFormatter().string(from: self)
    }
}
