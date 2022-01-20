//
//  EditScanCornerView.swift
//  WeScan
//
//  Created by Boris Emorine on 3/5/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import CoreImage
extension UIColor {
    func sscolor(hex: uint, alpha:CGFloat = 1.0) -> UIColor {
        UIColor(red: CGFloat(((hex & 0xFF0000) >> 16))/255.0,
                green: CGFloat(((hex & 0xFF00) >> 8))/255.0,
                blue:  CGFloat((hex & 0xFF)),
                               alpha: alpha)
                }
}

/// A UIView used by corners of a quadrilateral that is aware of its position.
open class EditScanCornerView: UIView {
    
    let position: CornerPosition
    
    /// The image to display when the corner view is highlighted.
    private var image: UIImage?
    private(set) var isHighlighted = false
    
//    private lazy var circleLayer: CAShapeLayer = {
//        let layer = CAShapeLayer()
//        layer.fillColor = UIColor(hex: 0x242739).cgColor
//        layer.strokeColor = UIColor(hex: 0xFFB82A).cgColor
//        layer.lineWidth = 2.0
//        return layer
//    }()

    /// Set stroke color of coner layer
    public var strokeColor: CGColor?
//    {
//        didSet {
//            circleLayer.strokeColor = strokeColor
//        }
//    }
    init(frame: CGRect, position: CornerPosition) {
        self.position = position
        super.init(frame: frame)
        backgroundColor = UIColor.color(hex: 0x242739)
        clipsToBounds = true
        self.layer.borderWidth = 2.0
        self.layer.borderColor = UIColor.color(hex: 0xFFB82A).cgColor
//        layer.addSublayer(circleLayer)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
//        layer.cornerRadius = min(bounds.width, bounds.height) / 2.0
    }
    
//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//
//        let bezierPath = UIBezierPath(ovalIn: rect.insetBy(dx: circleLayer.lineWidth, dy: circleLayer.lineWidth))
//        circleLayer.frame = rect
//        circleLayer.path = bezierPath.cgPath
//
//        image?.draw(in: rect)
//    }
//
//    func highlightWithImage(_ image: UIImage) {
//        isHighlighted = true
//        self.image = image
//        self.setNeedsDisplay()
//    }
//
//    func reset() {
//        isHighlighted = false
//        image = nil
//        setNeedsDisplay()
//    }
    
}
