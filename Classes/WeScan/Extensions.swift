//
//  Extensions.swift
//  SmartScannerSwiftLibBridge
//
//  Created by helfy on 2022/1/20.
//

extension UIColor {
   class func color(hex: uint, alpha:CGFloat = 1.0) -> UIColor {
        UIColor(red: CGFloat(((hex & 0xFF0000) >> 16))/255.0,
                green: CGFloat(((hex & 0xFF00) >> 8))/255.0,
                blue:  CGFloat((hex & 0xFF))/255.0,
                               alpha: alpha)
                }
}
