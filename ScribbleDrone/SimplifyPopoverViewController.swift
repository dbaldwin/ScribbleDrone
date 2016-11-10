//
//  SimplifyPopoverViewController.swift
//  ScribbleDrone
//
//  Created by Dennis Baldwin on 11/9/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit

protocol SimplifyPopoverViewControllerDelegate {
    
    func updateSimplifiedPath2(tolerance: Float)
    
}

class SimplifyPopoverViewController: UIViewController {

    @IBOutlet weak var simplifySlider: UISlider!
    var delegate : SimplifyPopoverViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    @IBAction func touchUpInside(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        
        delegate?.updateSimplifiedPath2(tolerance: slider.value)
        
    }
    
    /*func updateSimplifiedPath(_ sender: AnyObject) {
        
        googleMapView.clear()
        
        let slider = sender as! UISlider
        
        print("Updating path with tolerance: " + String(slider.value))
        
        drawSimplifiedGooglePath(tolerance: slider.value)
        
    }*/
}
