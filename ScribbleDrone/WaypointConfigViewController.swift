//
//  WaypointConfigViewController.swift
//  ScribbleDrone
//
//  Created by Dennis Baldwin on 11/28/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit

protocol WaypointConfigViewControllerDelegate {
    
    func updateWaypointConfig(index: Int, altitude: Float, delay: Int)
    
}

class WaypointConfigViewController: UIViewController {
    
    var altitude:Float = 25.0
    var delay:Int = 0
    
    var delegate : WaypointConfigViewControllerDelegate?
    
    @IBOutlet weak var waypointLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var altitudeSlider: UISlider!
    
    @IBOutlet weak var delayLabel: UILabel!
    @IBOutlet weak var delaySlider: UISlider!
    
    var waypointIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        waypointLabel.text = "WAYPOINT #\(waypointIndex+1)"
        altitudeSlider.value = altitude
        altitudeLabel.text = "ALTITUDE: \(altitude) m"
        
        delayLabel.text = "DELAY: \(delay) s"
        delaySlider.value = Float(delay)
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func saveWaypointConfig(_ sender: Any) {
        
        delegate?.updateWaypointConfig(index: waypointIndex, altitude: altitude, delay: delay)
        dismiss(animated: true, completion: nil)
        
    }

    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func updateAltitude(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        altitude = roundf(slider.value)
        altitudeLabel.text = "ALTITUDE: \(altitude) m"
        
    }
    
    
    @IBAction func updateDelay(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        delay = Int(slider.value)
        delayLabel.text = "DELAY: \(delay) s"
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
