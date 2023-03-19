//
//  UIColor.swift
//  Trails
//
//  Created by Jack Finnis on 19/03/2023.
//

import UIKit

extension UIColor {
    func brightness(_ amount: Double) -> UIColor? {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: brightness * amount, alpha: alpha)
        } else {
            return nil
        }
    }
}
