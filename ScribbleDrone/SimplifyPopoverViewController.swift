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
    func saveSimplifySliderValue(value: Float)
    
}

class SimplifyPopoverViewController: UIViewController {

    @IBOutlet weak var simplifySlider: UISlider!
    var delegate: SimplifyPopoverViewControllerDelegate?
    var simplifySliderValue: Float = 0
    
    override func viewDidLoad() {

        super.viewDidLoad()
        simplifySlider.value = simplifySliderValue
        
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        
        let slider = sender as! UISlider
        
        delegate?.updateSimplifiedPath(tolerance: slider.value)
        
    }
    
    @IBAction func touchUpInside(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        
        delegate?.saveSimplifySliderValue(value: slider.value)
        
        self.dismiss(animated: true, completion: nil)
        
    }

}
