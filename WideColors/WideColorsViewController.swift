//
//  ViewController.swift
//  WideColors
//
//  Created by Peter Strand on 2017-02-12.
//  Copyright © 2017 Nena Innovation AB. All rights reserved.
//

import UIKit

class WideColorsViewController: UIViewController {

  @IBOutlet weak var referenceImage: UIImageView!
  @IBOutlet weak var coreGraphicsView: CoreGraphicsView!
  @IBOutlet weak var openglView: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    let img = self.referenceImage.image
    coreGraphicsView.image = img?.cgImage
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

