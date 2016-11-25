//
//  MissionParamsViewController.swift
//  ScribbleDrone
//
//  Created by Dennis Baldwin on 11/10/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit

protocol MissionParamsViewControllerDelegate {
    
    func go(pathType: Int, altitude: Float, speed: Float)
    
}

class MissionParamsViewController: UIViewController {
    
    
    var speed:Float = 5.0
    var altitude:Float = 25.0
    var pathType:Int = 0
    
    var delegate : MissionParamsViewControllerDelegate?
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeSlider: UISlider!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var flightPathSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        
        flightPathSegmentedControl.selectedSegmentIndex = pathType
        
        // Set the slider values which can be passed from the main VC so we can persist the values
        speedSlider.value = speed
        altitudeSlider.value = altitude
        altitudeLabel.text = "ALTITUDE: " + String(altitude) + " m"
        speedLabel.text = "SPEED: " + String(speed) + " m/s"
        
        super.viewDidLoad()
        
    }
    
    @IBAction func flightPathChanged(_ sender: Any) {
        
        let control = sender as! UISegmentedControl
        pathType = control.selectedSegmentIndex
        
    }
    
    @IBAction func updateAltitude(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        altitude = roundf(slider.value)
        altitudeLabel.text = "ALTITUDE: " + String(altitude) + " m"
        
    }
    
    
    @IBAction func updateSpeed(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        speed = roundf(slider.value)
        speedLabel.text = "SPEED: " + String(speed) + " m/s"
        
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    @IBAction func launch(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
        delegate?.go(pathType: pathType, altitude: altitude, speed: speed)
        
    }
    
    
}
