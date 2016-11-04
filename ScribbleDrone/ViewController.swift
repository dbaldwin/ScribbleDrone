//
//  ViewController.swift
//  ScribbleDrone
//
//  Created by Dennis Baldwin on 10/30/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import GoogleMaps
import DJISDK

class ViewController: UIViewController {
    
    @IBOutlet weak var googleMapView: GMSMapView!
    
    @IBOutlet weak var toleranceSlider: UISlider!
    
    @IBOutlet weak var waypointLabel: UILabel!
    
    @IBOutlet weak var toleranceLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var satellitesLabel: UILabel!
    
    
    var coordinates = [CLLocationCoordinate2D]()
    
    var waypointMission:DJIWaypointMission = DJIWaypointMission()
    
    var missionManager:DJIMissionManager = DJIMissionManager.sharedInstance()!
    
    // Stores coordinates that are used to create the waypoint mission
    var waypointList: [AnyObject]=[]
    
    var isMapCenteredOnAircraft = false
    
    var aircraftHeading:CLLocationDegrees = 0
    
    var aircraftLocation:CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    var aircraftMarker = GMSMarker()
    
    
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
        
        // Register the app with DJI's servers
        DJISDKManager.registerApp("aea456f841549cf018a786d3", with: self)
        
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
        
        // Remove all waypoints from the list
        waypointList.removeAll()
        
        // Add coordinates to the path
        for loc in simplified {
        
            path.add(loc)
            
            // Add waypoint marker to the map
            addMarker(loc: loc)
            
            // Initialize the waypoint
            let waypoint: DJIWaypoint = DJIWaypoint(coordinate: loc)
            
            // Setting altitude to 20m for now
            waypoint.altitude = 20
            
            // Add waypoint to the list
            waypointList.append(waypoint)
        }
        
        // Update the distance label
        let distance = GMSGeometryLength(path)
        
        distanceLabel.text = "Distance: " + String(Int(distance)) + " ft"
        
        let polyLine = GMSPolyline(path: path)
        polyLine.strokeWidth = 3
        polyLine.strokeColor = UIColor.magenta
        polyLine.map = googleMapView
        
        // Add aircraft back to the map
        updateAircraftLocation()
        
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
        
        // Add aircraft back to the map
        updateAircraftLocation()
        
    }
    
    
    @IBAction func launchMission(_ sender: AnyObject) {
        
        // Remove all waypoints from mission before adding them
        waypointMission.removeAllWaypoints()
        
        // Setup mission parameters
        waypointMission.maxFlightSpeed = 10
        waypointMission.autoFlightSpeed = 5
        waypointMission.finishedAction = DJIWaypointMissionFinishedAction.goHome
        waypointMission.headingMode = DJIWaypointMissionHeadingMode.auto
        waypointMission.flightPathMode = DJIWaypointMissionFlightPathMode.curved
        
        // Add the waypoint list to the mission
        waypointMission.addWaypoints(waypointList)
        
        // Upload the mission
        missionManager.prepare(self.waypointMission, withProgress:
        {[weak self] (progress: Float) -> Void in
            
            // This is where the upload status will go
            
        }, withCompletion:{[weak self] (error: Error?) -> Void in
            
            
            if (error != nil) {
                
                print("Error uploading mission: \(error)")
                
            } else {
                
                print("Mission uploaded successfully")
                
                // Now begin the mission
                self?.missionManager.startMissionExecution(completion: {[weak self] (error: Error?) -> Void in
                    if (error != nil ) {
                        
                        print("Error starting mission: \(error)")
                        
                    } else {
                        
                        print("Launching mission")
                        
                    }
                })
                
            }
            
        })
    }
    
    
    func updateAircraftLocation() {
        
        // Display aircraft marker
        aircraftMarker.position = aircraftLocation
        
        if(aircraftHeading < 0) {
            aircraftHeading = aircraftHeading + 360;
        }
        
        aircraftMarker.rotation = aircraftHeading
        aircraftMarker.icon = UIImage(named: "aircraft")
        aircraftMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        aircraftMarker.map = googleMapView
        
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

// MARK: DJISDKManagerDelegate
extension ViewController : DJISDKManagerDelegate
{
    func sdkManagerDidRegisterAppWithError(_ error: Error?) {
        
        guard error == nil  else {
            print("Error:\(error!.localizedDescription)")
            return
        }
        
        print("Registered!")
        
        /*if enterDebugMode {
            DJISDKManager.enterDebugMode(withDebugId: "10.81.2.28")
        }else{
            DJISDKManager.startConnectionToProduct()
        }*/
        
        DJISDKManager.enterDebugMode(withDebugId: "10.0.1.8")
        
        //DJISDKManager.startConnectionToProduct()
        
    }
    
    func sdkManagerProductDidChange(from oldProduct: DJIBaseProduct?, to newProduct: DJIBaseProduct?) {
        
        guard let newProduct = newProduct else
        {
            print("Product Disconnected")
            return
        }
        
        //Updates the product's model
        if let oldProduct = oldProduct {
            print("Product changed from: \(oldProduct.model) to \((newProduct.model)!)")
        }
        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            print("Firmware package version is: \(version ?? "Unknown")")
            
        }
        
        //Updates the product's connection status
        print("Product Connected")
        statusLabel.text = "Status: Connected"
        
        // Setup the flight controller delegate
        let fc = (DJISDKManager.product() as! DJIAircraft).flightController
        fc?.delegate = self
        
    }
    
    func product(_ product: DJIBaseProduct, connectivityChanged isConnected: Bool) {
        if isConnected {
            
            statusLabel.text = "Status: Connected"
            print("Product Connected")
            
        } else {
            
            statusLabel.text = "Status: Disconnected"
            print("Product Disconnected")
        }
    }
    
}

// MARK: DJIFlightControllerDelegate
extension ViewController : DJIFlightControllerDelegate {
    
    func flightController(_ fc: DJIFlightController, didUpdateSystemState state: DJIFlightControllerCurrentState) {
        
        satellitesLabel.text = "Satellites: " + String(state.satelliteCount)
        aircraftLocation = state.aircraftLocation
        aircraftHeading = (fc.compass?.heading)!
        
        if(!isMapCenteredOnAircraft) {
            
            print("Centering map")
            
            isMapCenteredOnAircraft = true
            
            let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: state.aircraftLocation.latitude, longitude: state.aircraftLocation.longitude, zoom: 16)
            googleMapView.camera = camera
            
        }
        
        updateAircraftLocation()
        
        
        //self.headingLabel.text = String(format: "%0.1f", fc.compass!.heading)
        
        
    }
    
}
