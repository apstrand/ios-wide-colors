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
  
  override func draw(_ rect: CGRect) {
    let ctx = UIGraphicsGetCurrentContext()
    
    if let img = self.image {
      ctx?.draw(img, in: rect)
    }
    
  }
  
}
