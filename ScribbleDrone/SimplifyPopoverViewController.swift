//
//  SimplifyPopoverViewController.swift
//  ScribbleDrone
//
//  Created by Dennis Baldwin on 11/9/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit

protocol SimplifyPopoverViewControllerDelegate {
    
    func updateSimplifiedPath(tolerance: Float)
    
}

class SimplifyPopoverViewController: UIViewController {

    @IBOutlet weak var simplifySlider: UISlider!
    var delegate : SimplifyPopoverViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    @IBAction func touchUpInside(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        
        delegate?.updateSimplifiedPath(tolerance: slider.value)
        
    }

}
