//
//  UIColor.swift
//  Trails
//
//  Created by Jack Finnis on 19/03/2023.
//

import UIKit

extension UIColor {
    func darker() -> UIColor? {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: brightness * (UITraitCollection.current.userInterfaceStyle == .light ? 0.6 : 0.8), alpha: alpha)
        } else {
            return nil
        }
    }
}
