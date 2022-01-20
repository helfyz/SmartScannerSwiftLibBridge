//
//  ZoomGestureController.swift
//  WeScan
//
//  Created by Bobo on 5/31/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

open class ZoomGestureController:NSObject {
    
    private let image: UIImage
    private let quadView: QuadrilateralView
    private var previousPanPosition: CGPoint?
    private var curCorner: EditScanCornerView?

    @objc public init(image: UIImage, quadView: QuadrilateralView) {
        self.image = image
        self.quadView = quadView
    }

    @objc public func handle(pan: UIGestureRecognizer) {
    
        guard pan.state != .ended else {
            self.previousPanPosition = nil
            self.curCorner = nil
            return
        }
        
        let position = pan.location(in: quadView)
        
        let previousPanPosition = self.previousPanPosition ?? position
   
        let offset = CGAffineTransform(translationX: position.x - previousPanPosition.x, y: position.y - previousPanPosition.y)
        let cornerView = (self.curCorner != nil) ? self.curCorner : quadView.cornerViewFor(point: position) //quadView.cornerViewForCornerPosition(position: closestCorner)
        if let cornerView = cornerView {
            let draggedCornerViewCenter = cornerView.center.applying(offset)
            quadView.moveCorner(cornerView: cornerView, atPoint: draggedCornerViewCenter)
            
            self.previousPanPosition = position
            self.curCorner = cornerView;
           
        }
       
        
//        let scale = image.size.width / quadView.bounds.size.width
//        let scaledDraggedCornerViewCenter = CGPoint(x: draggedCornerViewCenter.x * scale, y: draggedCornerViewCenter.y * scale)
//        guard let zoomedImage = image.scaledImage(atPoint: scaledDraggedCornerViewCenter, scaleFactor: 2.5, targetSize: quadView.bounds.size) else {
//            return
//        }
        
//        quadView.highlightCornerAtPosition(position: closestCorner, with: zoomedImage)
    }
    
}
