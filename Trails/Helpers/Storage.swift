//
//  Defaults.swift
//  MyMap
//
//  Created by Jack Finnis on 17/01/2023.
//

import Foundation

@propertyWrapper
struct Storage<T: Codable> {
    let key: String
    let defaultValue: T
    
    init(wrappedValue defaultValue: T, _ key: String) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    let defaults = UserDefaults.standard
    var wrappedValue: T {
        get {
            guard let data = defaults.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data)
            else { return defaultValue }
            return value
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: key)
        }
    }
}
