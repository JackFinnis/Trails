//
//  Defaults.swift
//  MyMap
//
//  Created by Jack Finnis on 17/01/2023.
//

import Foundation

@propertyWrapper
struct Defaults<T> {
    let key: String
    let defaultValue: T
    
    init(wrappedValue defaultValue: T, _ key: String) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    let defaults = UserDefaults.standard
    var wrappedValue: T {
        get {
            defaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
}
