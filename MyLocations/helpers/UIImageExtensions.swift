//
//  UIImageExtensions.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 15/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

extension UIImage {
    func resized(withBounds bounds: CGSize) -> UIImage {
        let horizontalRatio = bounds.width / size.width
        let veriticalRatio = bounds.height / size.height
        let ratio = max(horizontalRatio, veriticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}
