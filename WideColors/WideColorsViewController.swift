//
//  ViewController.swift
//  WideColors
//
//  Created by Peter Strand on 2017-02-12.
//  Copyright © 2017 Nena Innovation AB. All rights reserved.
//

import UIKit
import GLKit

class WideColorsViewController: UIViewController {

  @IBOutlet weak var referenceImage: UIImageView!
  @IBOutlet weak var coreGraphicsView: CoreGraphicsView!
  @IBOutlet weak var glkView: GLKView!
  @IBOutlet weak var metalView: UIView!
  
  var metal: Metal!
  var opengl: OpenGL!

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    metal = Metal(metalView)
    opengl = OpenGL()

    self.referenceImage.layer.magnificationFilter = kCAFilterNearest
    if let image = self.referenceImage.image?.cgImage {
      coreGraphicsView.image = image
      opengl.setup(glkView, image: image)
    }
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

