//
//  CoreGraphicsView.swift
//  WideColors
//
//  Created by Peter Strand on 2017-02-12.
//  Copyright © 2017 Nena Innovation AB. All rights reserved.
//

import Foundation
import UIKit

class CoreGraphicsView: UIView {
  
  var image: CGImage?
  
  enum DrawMethod {
    case Immediate
    case NarrowImage
    case WideImage
  }
  var drawMethod: DrawMethod = .Immediate
  
  override func draw(_ drawRect: CGRect) {
    guard let ctx = UIGraphicsGetCurrentContext() else {
      return
    }

    guard let img = self.image else {
      ctx.setFillColor(UIColor.red.cgColor)
      ctx.fill(drawRect)
      return
    }

    let imgRect = CGRect(origin: CGPoint.zero, size: CGSize(width: img.width, height: img.height))
    
    switch drawMethod {
    case .Immediate:
      ctx.draw(img, in: drawRect)
    case .NarrowImage:

      UIGraphicsBeginImageContextWithOptions(drawRect.size, true, 1.0)
      if let subctx = UIGraphicsGetCurrentContext() {
        
        subctx.draw(img, in: imgRect)
        
        if let drawImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage {
          ctx.draw(drawImage, in: drawRect)
        }
      }
      UIGraphicsEndImageContext();
      
      break
    case .WideImage:
      let fmt = UIGraphicsImageRendererFormat()
      fmt.prefersExtendedRange = true
      let renderer = UIGraphicsImageRenderer(size: drawRect.size, format: fmt)
      
      if let subimg = renderer.image(actions: { ctx in
        ctx.cgContext.draw(img, in: imgRect)
        return
      }).cgImage {
        ctx.draw(subimg, in: drawRect)
      }
      break
    }
    
    
  }
  
}
