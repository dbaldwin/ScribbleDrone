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

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var googleMapView: GMSMapView!
    
    @IBOutlet weak var waypointLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var satellitesLabel: UILabel!
    
    var coordinates = [CLLocationCoordinate2D]()
    
    var waypointMission:DJIWaypointMission = DJIWaypointMission()
    
    var missionManager:DJIMissionManager = DJIMissionManager.sharedInstance()!
    
    // Stores coordinates that are used to create the waypoint mission
    var waypointList: [DJIWaypoint]=[]
    
    var isMapCenteredOnAircraft = false
    
    var aircraftHeading:CLLocationDegrees = 0
    
    var aircraftLocation:CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    var aircraftMarker = GMSMarker()
    
    var simplifiedTolerance : Float = 0
    
    
    lazy var canvasView:CanvasView = {
        
        var overlayView = CanvasView(frame: self.googleMapView.frame)
        overlayView.isUserInteractionEnabled = true
        overlayView.delegate = self
        return overlayView
        
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 41.850033, longitude: -87.6500523, zoom: 16)
        googleMapView.camera = camera
        googleMapView.isMyLocationEnabled = true
        
        googleMapView.mapType = kGMSTypeHybrid
        googleMapView.isMyLocationEnabled = true;
        googleMapView.settings.myLocationButton = true;
        googleMapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        
        // Creates a marker in the center of the map.
        /*let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = googleMapView*/
        
        // Register the app with DJI's servers
        DJISDKManager.registerApp("aea456f841549cf018a786d3", with: self)
        
        // We'll use to detect marker drag/drop
        googleMapView.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addMarker(loc: CLLocationCoordinate2D, index: Int) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5);
        marker.icon = UIImage(named: "waypoint");
        marker.isDraggable = true
        marker.userData = index
        marker.map = googleMapView
    }
    
    // Take the coordinates drawn from the canvas view and simplifies them based on tolerance
    func drawSimplifiedGooglePath(tolerance: Float) {
        
        print("Path tolerance: " + String(tolerance))
        
        print("There are " + String(coordinates.count) + " coordinates")
        
        let simplifiedCoordinates = SwiftSimplify.simplify(coordinates, tolerance: tolerance, highQuality: true)
        
        print("Number of points before simplification: " + String(coordinates.count))
        
        print("Number of points after simplification " + String(simplifiedCoordinates.count))
        
        waypointLabel.text = "Waypoints: " + String(simplifiedCoordinates.count)
        
        // Get rid of the canvas view
        self.canvasView.removeFromSuperview()
        self.canvasView.image = nil
        
        // Draw the path on the map
        addPathToMap(locations: simplifiedCoordinates)
        
    }
    
    // Draw the path on the map
    func addPathToMap(locations: [CLLocationCoordinate2D]) {
        
        // Remove all waypoints from the list
        waypointList.removeAll()
        
        // Loop through the coordinates and create the polyline
        let path = GMSMutablePath()
        
        // Store the marker's index so we can reference it on drag/drop events
        var index = 0
        
        // Add coordinates to the path
        for loc in locations {
            
            path.add(loc)
            
            // Add waypoint marker to the map
            addMarker(loc: loc, index: index)
            
            // Initialize the waypoint
            let waypoint: DJIWaypoint = DJIWaypoint(coordinate: loc)
            
            // Setting altitude to 20m for now
            waypoint.altitude = 20
            
            //waypoint.cornerRadiusInMeters = abcd
            
            // Add waypoint to the list
            waypointList.append(waypoint)
            
            index = index + 1
        }
        
        let polyLine = GMSPolyline(path: path)
        polyLine.strokeWidth = 3
        polyLine.strokeColor = UIColor.magenta
        polyLine.map = googleMapView
        
        // Update the distance label
        let distance = GMSGeometryLength(path)
        distanceLabel.text = "Distance: " + String(Int(distance)) + " ft"
        
        // Add aircraft back to the map since it will be cleared when this function is called
        updateAircraftLocation()
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
    
    @IBAction func tiltMap(_ sender: AnyObject) {
        
        let toggle = sender as! UISwitch
        
        if(toggle.isOn) {
            googleMapView.animate(toViewingAngle: 90)
        } else {
            googleMapView.animate(toViewingAngle: 0)
        }
        
    }
    
    // Handles the segue = display a small popover for the simply slider
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "simplifySegue" {
            
            let vc = segue.destination as! SimplifyPopoverViewController
            vc.preferredContentSize = CGSize(width: 275, height: 75)
            
            // This is so we can receive slider events from the popup
            vc.delegate = self
        
            let controller = vc.popoverPresentationController
            // Don't display a popover arrow
            controller?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            controller?.delegate = self
            
        }
        
    }
    
    // This is used to properly display a popover on iPhone
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return .none
        
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
    
    //Angle in Radians
    func rotateAroundXAxis(angle: Double) -> [CLLocationCoordinate3D] {
        
        let coordinates = SwiftSimplify.simplify(self.coordinates, tolerance: self.simplifiedTolerance, highQuality: true)
        
        var newCoordinates = [CLLocationCoordinate3D]()
        
        newCoordinates.append(CLLocationCoordinate3D(longitude: coordinates[0].longitude, latitude: coordinates[0].latitude, altitude: waypointList[0].altitude))
        
        for i in 1..<coordinates.count {
            newCoordinates.append(CLLocationCoordinate3D(longitude: coordinates[i].longitude, latitude: newCoordinates[i-1].latitude+(coordinates[i].latitude-coordinates[i-1].latitude)*cos(angle), altitude: newCoordinates[i-1].altitude+Float(GMSGeometryDistance(CLLocationCoordinate2D(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude), CLLocationCoordinate2D(latitude: coordinates[i-1].latitude, longitude: coordinates[i].longitude))*sin(angle)*(((coordinates[i].latitude-coordinates[i-1].latitude)<0) ? -1:1))))
        }
        
        print(newCoordinates[1])
        
        return newCoordinates
    }
    
    @IBAction func tiltAngleChanged(_ sender: UISlider) {
        print(sin(sender.value))
        googleMapView.clear()
        let newCoordinates = rotateAroundXAxis(angle: Double(sender.value))
        addPathToMap(locations: newCoordinates.map{return CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)})
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
        
        //DJISDKManager.enterDebugMode(withDebugId: "10.0.1.8")
        
        DJISDKManager.startConnectionToProduct()
        
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

// MARK: GMSMapViewDelegate
extension ViewController : GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        
        // Get the marker index so we can update the coordinates array
        let index = marker.userData as! Int
        
        // Update the coordinate of the dropped marker
        coordinates[index] = marker.position
        
        // Clear the map
        googleMapView.clear()
        
        // Redraw the path
        addPathToMap(locations: coordinates)
        
    }
    
}

// MARK: SimplifyPopoverViewControllerDelegate
extension ViewController : SimplifyPopoverViewControllerDelegate {
    
    func updateSimplifiedPath(tolerance: Float) {
        
        print("Tolerance is this: " + String(tolerance))
        
        self.simplifiedTolerance = tolerance
        
        googleMapView.clear()
        
        drawSimplifiedGooglePath(tolerance: tolerance)
        
    }
    
}

struct CLLocationCoordinate3D {
    var longitude, latitude : CLLocationDegrees
    var altitude : Float
}


