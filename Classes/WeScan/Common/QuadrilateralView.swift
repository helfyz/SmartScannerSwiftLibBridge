//
//  RectangleView.swift
//  WeScan
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

/// Simple enum to keep track of the position of the corners of a quadrilateral.
enum CornerPosition {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
    
    case top
    case left
    case rigth
    case bottom
}

/// The `QuadrilateralView` is a simple `UIView` subclass that can draw a quadrilateral, and optionally edit it.
open class QuadrilateralView: UIView {
    
    private let quadLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.color(hex: 0xFFB82A).cgColor
        layer.lineWidth = 2.0
        layer.opacity = 1.0
        layer.isHidden = true
        
        return layer
    }()
    
    /// We want the corner views to be displayed under the outline of the quadrilateral.
    /// Because of that, we need the quadrilateral to be drawn on a UIView above them.
    private let quadView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// The quadrilateral drawn on the view.
    private(set) var quad: Quadrilateral?
    
    @objc
    public var editable = false {
        didSet {
            cornerViews(hidden: !editable)  
            quadLayer.fillColor = editable ? UIColor.clear.cgColor : UIColor.color(hex: 0xFFB82A).withAlphaComponent(0.1).cgColor
            guard let quad = quad else {
                return
            }
            drawQuad(quad, animated: false)
            layoutCornerViews(forQuad: quad)
        }
    }

    /// Set stroke color of image rect and corner.
   @objc
    public var strokeColor: CGColor? {
        didSet {
            quadLayer.strokeColor = strokeColor
            for view in cornersView {
                view.strokeColor = strokeColor
            }
        }
    }
    
    private var isHighlighted = false {
        didSet (oldValue) {
            guard oldValue != isHighlighted else {
                return
            }
            quadLayer.fillColor = UIColor.clear.cgColor //isHighlighted ? UIColor.clear.cgColor : UIColor(white: 0.0, alpha: 0.6).cgColor
            isHighlighted ? bringSubviewToFront(quadView) : sendSubviewToBack(quadView)
        }
    }
    private lazy var cornersView: [EditScanCornerView] = {
        return [topLeftCornerView,topRightCornerView,bottomRightCornerView,bottomLeftCornerView,topCornerView,leftCornerView,rightCornerView,bottomCornerView]
    }()
    private lazy var topCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: CGSize(width: 100.0, height: cornerViewSize.height)), position: .top)
    }()
    private lazy var leftCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: CGSize(width: cornerViewSize.width, height:100.0)), position: .left)
    }()
    private lazy var rightCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: CGSize(width: cornerViewSize.width, height:100.0)), position: .rigth)
    }()
    private lazy var bottomCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: CGSize(width: 100.0, height: cornerViewSize.height)), position: .bottom)
    }()
    
    private lazy var topLeftCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: cornerViewSize), position: .topLeft)
    }()
    
    private lazy var topRightCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: cornerViewSize), position: .topRight)
    }()
    
    private lazy var bottomRightCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: cornerViewSize), position: .bottomRight)
    }()
    
    private lazy var bottomLeftCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: cornerViewSize), position: .bottomLeft)
    }()
    
    private let highlightedCornerViewSize = CGSize(width: 75.0, height: 75.0)
    private let cornerViewSize = CGSize(width: 10.0, height: 10.0)
    
    // MARK: - Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        addSubview(quadView)
        setupCornerViews()
        setupConstraints()
        quadView.layer.addSublayer(quadLayer)
    }
    
    private func setupConstraints() {
        let quadViewConstraints = [
            quadView.topAnchor.constraint(equalTo: topAnchor),
            quadView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomAnchor.constraint(equalTo: quadView.bottomAnchor),
            trailingAnchor.constraint(equalTo: quadView.trailingAnchor)
        ]
        
        NSLayoutConstraint.activate(quadViewConstraints)
    }
    
    private func setupCornerViews() {
        for view in cornersView {
            addSubview(view)
        }
    }
    override public func layoutSubviews() {
        super.layoutSubviews()
        guard quadLayer.frame != bounds else {
            return
        }
        
        quadLayer.frame = bounds
        if let quad = quad {
            drawQuadrilateral(quad: quad, animated: false)
        }
    }
    
    // MARK: - Drawings
    
    /// Draws the passed in quadrilateral.
    ///
    /// - Parameters:
    ///   - quad: The quadrilateral to draw on the view. It should be in the coordinates of the current `QuadrilateralView` instance.
    func drawQuadrilateral(quad: Quadrilateral, animated: Bool) {
        self.quad = quad
        drawQuad(quad, animated: animated)
        if editable {
            cornerViews(hidden: false)
            layoutCornerViews(forQuad: quad)
        }
    }
    
    private func drawQuad(_ quad: Quadrilateral, animated: Bool) {
        let path = quad.path
        
//        if editable {
//            path = path.reversing()
//            let rectPath = UIBezierPath(rect: bounds)
//            path.append(rectPath)
//        }
        
        if animated == true {
            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.duration = 0.2
            quadLayer.add(pathAnimation, forKey: "path")
        }
        
        quadLayer.path = path.cgPath
        quadLayer.isHidden = false
    }
    
    private func layoutCornerViews(forQuad quad: Quadrilateral) {
        topLeftCornerView.center = quad.topLeft
        topRightCornerView.center = quad.topRight
        bottomLeftCornerView.center = quad.bottomLeft
        bottomRightCornerView.center = quad.bottomRight
        
        topCornerView.center = CGPoint(x: (quad.topLeft.x + quad.topRight.x) / 2.0, y: (quad.topLeft.y + quad.topRight.y) / 2.0)
        var cc = angleBetweenPoints(first: topCornerView.center, second: quad.topRight)
        topCornerView.transform = CGAffineTransform(rotationAngle: -cc)
       
        
        leftCornerView.center = CGPoint(x: (quad.topLeft.x + quad.bottomLeft.x) / 2.0, y: (quad.topLeft.y + quad.bottomLeft.y) / 2.0)
        cc = angleBetweenPoints(first: leftCornerView.center, second: quad.topLeft )
        leftCornerView.transform = CGAffineTransform(rotationAngle: -cc + CGFloat((Double.pi / 2.0)))
        
        rightCornerView.center = CGPoint(x: (quad.topRight.x + quad.bottomRight.x) / 2.0, y: (quad.topRight.y + quad.bottomRight.y) / 2.0)
        cc = angleBetweenPoints(first: rightCornerView.center, second: quad.topRight)
        rightCornerView.transform = CGAffineTransform(rotationAngle: -cc + CGFloat((Double.pi / 2.0)))
        
        bottomCornerView.center = CGPoint(x: (quad.bottomLeft.x + quad.bottomRight.x) / 2.0, y: (quad.bottomLeft.y + quad.bottomRight.y) / 2.0)
        cc = angleBetweenPoints(first: bottomCornerView.center, second: quad.bottomRight)
        bottomCornerView.transform = CGAffineTransform(rotationAngle: -cc)
       
   
    }
    func angleBetweenPoints(first:CGPoint, second:CGPoint) -> CGFloat{
        let height = second.y - first.y;
        let width = first.x - second.x;
        let rads = atan(height/width);
        return rads;
    }
    func removeQuadrilateral() {
        quadLayer.path = nil
        quadLayer.isHidden = true
    }
    
    // MARK: - Actions
    @objc
    open func cornerViewFor(point: CGPoint) -> EditScanCornerView? {
       return  cornersView.first { (subView) -> Bool in
            let smallestDistance = point.distanceTo(point: subView.center)
            return smallestDistance < 40
        }
    }
    
    func moveCorner(cornerView: EditScanCornerView, atPoint point: CGPoint) {
        guard let quad = quad else {
            return
        }
        
        let validPoint = self.validPoint(point, forCornerViewOfSize: cornerView.bounds.size, inView: self)
//
        let updatedQuad = update(quad, withPosition: validPoint, forCorner: cornerView.position)
  
        self.quad = updatedQuad
        drawQuad(updatedQuad, animated: false)
        layoutCornerViews(forQuad: updatedQuad)
      
    }
    
    func highlightCornerAtPosition(position: CornerPosition, with image: UIImage) {
//        guard editable else {
//            return
//        }
//        isHighlighted = true
//
//        let cornerView = cornerViewForCornerPosition(position: position)
//        guard cornerView.isHighlighted == false else {
//            cornerView.highlightWithImage(image)
//            return
//        }
//
//        let origin = CGPoint(x: cornerView.frame.origin.x - (highlightedCornerViewSize.width - cornerViewSize.width) / 2.0,
//                             y: cornerView.frame.origin.y - (highlightedCornerViewSize.height - cornerViewSize.height) / 2.0)
//        cornerView.frame = CGRect(origin: origin, size: highlightedCornerViewSize)
//        cornerView.highlightWithImage(image)
    }
    
    func resetHighlightedCornerViews() {
        isHighlighted = false
        resetHighlightedCornerViews(cornerViews: [topLeftCornerView, topRightCornerView, bottomLeftCornerView, bottomRightCornerView, topCornerView])
    }
    
    private func resetHighlightedCornerViews(cornerViews: [EditScanCornerView]) {
        cornerViews.forEach { (cornerView) in
            resetHightlightedCornerView(cornerView: cornerView)
        }
    }
    
    private func resetHightlightedCornerView(cornerView: EditScanCornerView) {
//        cornerView.reset()
        let origin = CGPoint(x: cornerView.frame.origin.x + (cornerView.frame.size.width - cornerViewSize.width) / 2.0,
                             y: cornerView.frame.origin.y + (cornerView.frame.size.height - cornerViewSize.width) / 2.0)
        cornerView.frame = CGRect(origin: origin, size: cornerViewSize)
        cornerView.setNeedsDisplay()
    }
    
    // MARK: Validation
    
    /// Ensures that the given point is valid - meaning that it is within the bounds of the passed in `UIView`.
    ///
    /// - Parameters:
    ///   - point: The point that needs to be validated.
    ///   - cornerViewSize: The size of the corner view representing the given point.
    ///   - view: The view which should include the point.
    /// - Returns: A new point which is within the passed in view.
    private func validPoint(_ point: CGPoint, forCornerViewOfSize cornerViewSize: CGSize, inView view: UIView) -> CGPoint {
        var validPoint = point
        
        if point.x > view.bounds.width {
            validPoint.x = view.bounds.width
        } else if point.x < 0.0 {
            validPoint.x = 0.0
        }
        
        if point.y > view.bounds.height {
            validPoint.y = view.bounds.height
        } else if point.y < 0.0 {
            validPoint.y = 0.0
        }
        
        return validPoint
    }
    
    // MARK: - Convenience
    
    private func cornerViews(hidden: Bool) {
        for view in cornersView {
            view.isHidden = hidden
        }
    }
    
    private func update(_ quad: Quadrilateral, withPosition position: CGPoint, forCorner corner: CornerPosition) -> Quadrilateral {
        var quad = quad
        
        switch corner {
        case .topLeft:
            quad.topLeft = position
        case .topRight:
            quad.topRight = position
        case .bottomRight:
            quad.bottomRight = position
        case .bottomLeft:
            quad.bottomLeft = position
        case .top:
            let offset = position.y - topCornerView.center.y
            quad.topLeft.y += offset
            quad.topRight.y += offset
        case .left:
            let offset = position.x - leftCornerView.center.x
            quad.topLeft.x += offset
            quad.bottomLeft.x += offset
        case .rigth:
            let offset = position.x - rightCornerView.center.x
            quad.topRight.x += offset
            quad.bottomRight.x += offset
        case .bottom:
            let offset = position.y - bottomCornerView.center.y
            quad.bottomLeft.y += offset
            quad.bottomRight.y += offset
    
        }
        
        return quad
    }
    
    func cornerViewForCornerPosition(position: CornerPosition) -> EditScanCornerView {
        switch position {
        case .topLeft:
            return topLeftCornerView
        case .topRight:
            return topRightCornerView
        case .bottomLeft:
            return bottomLeftCornerView
        case .bottomRight:
            return bottomRightCornerView
        case .top:
            return topCornerView
        case .left:
            return leftCornerView
        case .rigth:
            return rightCornerView
        case .bottom:
            return bottomCornerView
      
        }
    }
}
