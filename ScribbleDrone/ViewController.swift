//
//  ViewController.swift
//  ScribbleDrone
//
//  Created by Dennis Baldwin on 10/30/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {
    
    @IBOutlet weak var googleMapView: GMSMapView!
    
    @IBOutlet weak var toleranceSlider: UISlider!
    
    @IBOutlet weak var waypointLabel: UILabel!
    
    @IBOutlet weak var toleranceLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!
    var coordinates = [CLLocationCoordinate2D]()
    
    
    lazy var canvasView:CanvasView = {
        
        var overlayView = CanvasView(frame: self.googleMapView.frame)
        overlayView.isUserInteractionEnabled = true
        overlayView.delegate = self
        return overlayView
        
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //googleMapView.delegate = self
        
        
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 41.850033, longitude: -87.6500523, zoom: 16)
        googleMapView.camera = camera
        googleMapView.isMyLocationEnabled = true
        
        googleMapView.mapType = kGMSTypeHybrid
        googleMapView.isMyLocationEnabled = true;
        googleMapView.settings.myLocationButton = true;
        
        // Creates a marker in the center of the map.
        /*let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = googleMapView*/
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addMarker(loc: CLLocationCoordinate2D) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5);
        marker.icon = UIImage(named: "waypoint");
        marker.map = googleMapView
    }
    
    // Take the coordinates drawn from the canvas view and simplifies them based on tolerance
    func drawSimplifiedGooglePath(tolerance: Float) {
        print("There are " + String(self.coordinates.count) + " coordinates")
        
        let simplified = SwiftSimplify.simplify(self.coordinates, tolerance: tolerance, highQuality: true)
        
        print("Number of points before simplification: " + String(self.coordinates.count))
        
        print("Number of points after simplification " + String(simplified.count))
        
        waypointLabel.text = "Waypoints: " + String(simplified.count)
        
        // Get rid of the canvas view
        self.canvasView.removeFromSuperview()
        self.canvasView.image = nil
        
        // Loop through the coordinates and create the polyline
        let path = GMSMutablePath()
        
        // Add coordinates to the path
        for loc in simplified {
            path.add(loc)
            
            // Add waypoint marker to the map
            addMarker(loc: loc)
        }
        
        // Update the distance label
        let distance = GMSGeometryLength(path)
        
        distanceLabel.text = "Distance: " + String(Int(distance)) + " ft"
        
        let polyLine = GMSPolyline(path: path)
        polyLine.strokeWidth = 3
        polyLine.strokeColor = UIColor.green
        polyLine.map = googleMapView
    }
    
    
    @IBAction func updateToleranceLabel(_ sender: AnyObject) {
        
        let slider = sender as! UISlider
        toleranceLabel.text = String(format: "%.4f", slider.value)
        
    }
    
    
    @IBAction func updateSimplifiedPath(_ sender: AnyObject) {
        
        googleMapView.clear()
        
        let slider = sender as! UISlider
        
        print("Updating path with tolerance: " + String(slider.value))
        
        drawSimplifiedGooglePath(tolerance: slider.value)
        
    }
    
    
    @IBAction func beginDrawing(_ sender: AnyObject) {
        
        // This adds the canvas view for drawing
        self.view.addSubview(canvasView)
        
    }
    
    
    @IBAction func resetDrawing(_ sender: AnyObject) {
        
        googleMapView.clear()
        
        self.coordinates.removeAll()
        self.canvasView.image = nil
        self.canvasView.removeFromSuperview()
        
        waypointLabel.text = "Waypoints: 0"
        toleranceSlider.value = 0.0
        toleranceLabel.text = "0.0"
        
        distanceLabel.text = "Distance: 0 ft"
        
    }
    
    
}

//MARK: GET DRAWABLE COORDINATES
extension ViewController:NotifyTouchEvents{
    
    func touchBegan(touch:UITouch){
        
        let location = touch.location(in: self.googleMapView)
        let coordinate = self.googleMapView.projection.coordinate(for: location)
        self.coordinates.append(coordinate)
        
    }
    
    func touchMoved(touch:UITouch){
        
        let location = touch.location(in: self.googleMapView)
        let coordinate = self.googleMapView.projection.coordinate(for: location)
        self.coordinates.append(coordinate)
        
    }
    
    func touchEnded(touch:UITouch){
        
        let location = touch.location(in: self.googleMapView)
        let coordinate = self.googleMapView.projection.coordinate(for: location)
        self.coordinates.append(coordinate)
        
        drawSimplifiedGooglePath(tolerance: 0)
        
        
    }
}
