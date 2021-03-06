
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

struct CLLocationCoordinate3D {
    var longitude, latitude : CLLocationDegrees
    var altitude : Float
}

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var googleMapView: GMSMapView!
    
    @IBOutlet weak var waypointLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var satellitesLabel: UILabel!
    
    @IBOutlet weak var flightTimeLabel: UILabel!
    
    @IBOutlet weak var altitudeLabel: UILabel!
    
    @IBOutlet weak var batteryLabel: UILabel!
    
    @IBOutlet weak var drawButton: UIButton!
    
    @IBOutlet weak var simplifyButton: UIButton!
    
    @IBOutlet weak var clearButton: UIButton!
    
    var coordinates = [CLLocationCoordinate2D]()
    
    var coordinates3D = [CLLocationCoordinate3D]()
    
    var simplifiedCoordinates = [CLLocationCoordinate2D]()
    
    var waypointMission:DJIWaypointMission = DJIWaypointMission()
    
    var missionManager:DJIMissionManager = DJIMissionManager.sharedInstance()!
    
    // Stores coordinates that are used to create the waypoint mission
    var waypointList: [DJIWaypoint]=[]
    
    var isMapCenteredOnAircraft = false
    
    var aircraftHeading: CLLocationDegrees = 0
    
    var aircraftLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    var aircraftMarker = GMSMarker()
    
    var simplifiedTolerance: Float = 0
    
    var simplifySliderValue: Float = 0
    
    var speed: Float = 5.0
    
    var missionAltitude: Float = 25.0
    
    // Linear = 0, Curved = 1
    var pathType: Int = 0
    
    // Hover = 0, RTH = 1
    var finishedType: Int = 0
    
    var distance: CLLocationDistance = 0.0
    
    var progressAlertView: UIAlertController? = nil
    
    var currentlySelectedMarker = GMSMarker()
    
    lazy var canvasView: CanvasView = {
        
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
        
        // Disable the buttons until a path is drawn
        toggleButtons(enabled: false)
        
        print("========= VIEWCONTROLLER VIEWDIDLOAD ==========")
        
        
    }
    
    // Handles the simplify and clear buttons
    func toggleButtons(enabled: Bool) {
        
        simplifyButton.isEnabled = enabled
        clearButton.isEnabled = enabled
        
        if(enabled) {
            simplifyButton.setTitleColor(UIColor.white, for: .normal)
            clearButton.setTitleColor(UIColor.white, for: .normal)
        } else {
            simplifyButton.setTitleColor(UIColor.lightGray, for: .normal)
            clearButton.setTitleColor(UIColor.lightGray, for: .normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addMarker(loc: CLLocationCoordinate2D, index: Int, icon: String) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.icon = UIImage(named: icon)
        marker.isDraggable = true
        marker.userData = index
        marker.map = googleMapView
    }
    
    // Take the coordinates drawn from the canvas view and simplifies them based on tolerance
    func drawSimplifiedGooglePath(tolerance: Float) {
        
        // Enable buttons after drawing
        toggleButtons(enabled: true)
        
        //print("Path tolerance: " + String(tolerance))
        
        print("There are " + String(coordinates.count) + " coordinates")
        
        simplifiedCoordinates = SwiftSimplify.simplify(coordinates, tolerance: tolerance, highQuality: true)
        
        //print("Number of points before simplification: " + String(coordinates.count))
        
        //print("Number of points after simplification " + String(simplifiedCoordinates.count))
        
        waypointLabel.text = "Waypoints: " + String(simplifiedCoordinates.count)
        
        // Get rid of the canvas view
        self.canvasView.removeFromSuperview()
        self.canvasView.image = nil
        
        // Deselect the draw button
        drawButton.backgroundColor = UIColor.black
        
        // Draw the path on the map
        addPathToMap(locations: simplifiedCoordinates)
        
        // Enable the buttons
        
    }
    
    /*func add3DPathToMap(locations: [CLLocationCoordinate3D]) {
        
        // Loop through the coordinates and create the polyline
        let path = GMSMutablePath()
        
        // Store the marker's index so we can reference it on drag/drop events
        var index = 0
        
        // Remove all waypoints from the list before we add them
        waypointList.removeAll()
        
        // Add coordinates to the path
        for loc in locations {
            
            let loc2D = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            
            // Initialize the waypoint
            let waypoint: DJIWaypoint = DJIWaypoint(coordinate: loc2D)
            
            // Set altitude for the waypoint
            waypoint.altitude = loc.altitude
            
            //waypoint.cornerRadiusInMeters = abcd
            
            // Add waypoint to the list
            waypointList.append(waypoint)
            
            path.add(loc2D)
            
            // Add waypoint marker to the map
            addMarker(loc: loc2D, index: index)
            
            index = index + 1
        }
        
        let polyLine = GMSPolyline(path: path)
        polyLine.strokeWidth = 3
        polyLine.strokeColor = UIColor.magenta
        polyLine.map = googleMapView
        
        // Update the distance label
        distance = GMSGeometryLength(path)
        distanceLabel.text = "Distance: " + String(Int(distance)) + " m"
        
        let flight_time = distance / Double(speed)
        
        flightTimeLabel.text = "Est. flight time : " + String(Int(flight_time)) + " s"
        
        // Add aircraft back to the map since it will be cleared when this function is called
        updateAircraftLocation()
    }*/
    
    // Draw the path on the map
    func addPathToMap(locations: [CLLocationCoordinate2D]) {
        
        // Loop through the coordinates and create the polyline
        let path = GMSMutablePath()
        
        // Store the marker's index so we can reference it on drag/drop events
        var index = 0
        
        // Remove all waypoints from the list before we add them
        waypointList.removeAll()
        
        // Add coordinates to the path
        for loc in locations {
            
            // Initialize the waypoint
            let waypoint: DJIWaypoint = DJIWaypoint(coordinate: loc)
            
            // Initialize all waypoints to the mission altitude
            waypoint.altitude = self.missionAltitude
            
            // In the future we could set this as a param to get a smoother flight
            //waypoint.cornerRadiusInMeters = abcd
            
            // Add waypoint to the list
            waypointList.append(waypoint)
            
            path.add(loc)
                
            addMarker(loc: loc, index: index, icon: "waypoint")
            
            index = index + 1
        }
        
        let polyLine = GMSPolyline(path: path)
        polyLine.strokeWidth = 3
        polyLine.strokeColor = UIColor.magenta
        polyLine.map = googleMapView
        
        // Update the distance label
        distance = GMSGeometryLength(path)
        distanceLabel.text = "Distance: " + String(Int(distance)) + " m"
        
        updateFlightTime()
        
        // Add aircraft back to the map since it will be cleared when this function is called
        updateAircraftLocation()
    }
    
    // Update flight time based on takeoff altitude, distance of path, and delay at waypoints
    func updateFlightTime() {
    
        let flight_time = Float(distance / Double(speed))
        
        // Trying to get this a little more accurate by including takeoff altitude
        let firstAltitude: Float = waypointList[0].altitude
        let takeoff_time = firstAltitude / speed
        
        var delay_time: Int = 0
        
        // Loop and add any waypoint delays
        for waypoint in waypointList {
            
            if waypoint.waypointActions.count > 0 {
                
                let action: DJIWaypointAction = waypoint.waypointActions[0] as! DJIWaypointAction
                delay_time += Int(action.actionParam)/1000
                
            }
            
        }
        
        flightTimeLabel.text = "Est. flight time : " + String(Int(flight_time + takeoff_time) + delay_time) + " s"
        
    }
    
    @IBAction func beginDrawing(_ sender: AnyObject) {
        
        (sender as! UIButton).backgroundColor = UIColor.darkGray
        
        // This adds the canvas view for drawing
        self.view.addSubview(canvasView)
        
    }
    
    
    @IBAction func resetDrawing(_ sender: AnyObject) {
        
        // Disable buttons
        toggleButtons(enabled: false)
        
        // Reset the slider value
        self.simplifySliderValue = 0
        
        googleMapView.clear()
        googleMapView.animate(toViewingAngle: 0)
        
        self.coordinates.removeAll()
        self.canvasView.image = nil
        self.canvasView.removeFromSuperview()
        
        waypointLabel.text = "Waypoints: 0"
        
        distanceLabel.text = "Distance: 0 m"
        
        flightTimeLabel.text = "Est. flight time: 0 s"
        
        // Add aircraft back to the map
        updateAircraftLocation()
        
    }
    
    
    func launchMission(pathType: Int, altitude: Float, speed: Float, finishedType: Int) {
        
        // Remove all waypoints from mission before adding them
        waypointMission.removeAllWaypoints()
        
        // Setup mission parameters
        waypointMission.maxFlightSpeed = 10
        waypointMission.autoFlightSpeed = speed
        
        if finishedType == 0 {
            
            waypointMission.finishedAction = DJIWaypointMissionFinishedAction.noAction
            
        } else {
            
            waypointMission.finishedAction = DJIWaypointMissionFinishedAction.goHome
            
        }
        
        waypointMission.headingMode = DJIWaypointMissionHeadingMode.controledByRemoteController
        
        if pathType == 0 {
            
            waypointMission.flightPathMode = DJIWaypointMissionFlightPathMode.normal
            
        } else if(pathType == 1) {
            
            waypointMission.flightPathMode = DJIWaypointMissionFlightPathMode.curved
            
        }
        
        // Let's loop through the waypoints and set the fixed altitude for the 2D flight from the params screen
        for waypoint in waypointList {      
            
            print("Altitude for waypoint is: \(waypoint.altitude)")
            print("Action count for waypoint is \(waypoint.waypointActions.count)")
            
        }
        
        // Add the waypoint list to the mission
        waypointMission.addWaypoints(waypointList)
        
        // Upload the mission
        missionManager.prepare(self.waypointMission, withProgress:
        {[weak self] (progress: Float) -> Void in
            
            // Show the progress of the mission upload
            let message: String = "\(Int(100 * progress))% complete"
            
            // If progress view doesn't exist let's create it
            if self?.progressAlertView == nil {
                self?.progressAlertView = UIAlertController(title: "Uploading Mission", message: message, preferredStyle: UIAlertControllerStyle.alert)
                self?.present((self?.progressAlertView)!, animated: true, completion: nil)
            }
            else {
                self?.progressAlertView!.message = message
            }
            
            // When mission is fully uploaded dismiss progress view
            if progress == 1.0 {
                self?.progressAlertView?.dismiss(animated: true, completion: nil)
                self?.progressAlertView = nil
            }
            
        }, withCompletion:{[weak self] (error: Error?) -> Void in
            
            // Dismiss the progress view
            if self?.progressAlertView != nil  {
                self?.progressAlertView?.dismiss(animated: true, completion: nil)
                self?.progressAlertView = nil
            }
            
            if (error != nil) {
                
                print("Error uploading mission: \(error)")
                self?.basicAlert(title: "Error Uploading Mission", message: error.debugDescription)
                
            } else {
                
                print("Mission uploaded successfully")
                
                // Now begin the mission
                self?.missionManager.startMissionExecution(completion: {[weak self] (error: Error?) -> Void in
                    if (error != nil ) {
                        
                        self?.basicAlert(title: "Error Starting Mission", message: error.debugDescription)
                        
                    } else {
                        
                        print("Launching mission")
                        
                    }
                })
                
            }
            
        })
    }
    
    func basicAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            print("Handle Ok logic here")
        }))
        
        present(alert, animated: true, completion: nil)

    }
    
    @IBAction func tiltMap(_ sender: AnyObject) {
        
        googleMapView.clear()
        
        let toggle = sender as! UISwitch
        
        // Vertical path
        if(toggle.isOn) {
            
            googleMapView.animate(toViewingAngle: 90)
            
            //let newCoordinates = rotateAroundXAxis(angle: 90.0)
            
            //add3DPathToMap(locations: newCoordinates)
        
        // Standard path
        } else {
            
            googleMapView.animate(toViewingAngle: 0)
            
            drawSimplifiedGooglePath(tolerance: simplifiedTolerance)
            
        }
        
    }
    
    // Handles the segue = display a small popover for the simply slider
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "simplifySegue" {
            
            let vc = segue.destination as! SimplifyPopoverViewController
            vc.preferredContentSize = CGSize(width: 500, height: 75)
            
            // This is so we can receive slider events from the popup
            vc.delegate = self
            
            // Set the slider value
            vc.simplifySliderValue = simplifySliderValue
        
            let controller = vc.popoverPresentationController
            // Don't display a popover arrow
            controller?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            controller?.delegate = self
            
        } else if segue.identifier == "missionParamsSegue" {
            
            // Setup the delegate so we can receive params for the mission (altitude, speed)
            let vc = segue.destination as! MissionParamsViewController
            vc.delegate = self
            
            // Pass these in for subsequent missions to maintain settings
            vc.speed = self.speed
            vc.altitude = self.missionAltitude
            vc.pathType = self.pathType
            vc.finishedType = self.finishedType
            
        } else if segue.identifier == "waypointConfigSegue" {
            
            let vc = segue.destination as! WaypointConfigViewController
            vc.delegate = self
            
            let index = currentlySelectedMarker.userData as! Int
            vc.waypointIndex = index
            vc.altitude = waypointList[index].altitude
            
            // Set the delay
            if waypointList[index].waypointActions.count > 0 {
            
                let action: DJIWaypointAction = waypointList[index].waypointActions[0] as! DJIWaypointAction
            
                vc.delay = Int(action.actionParam/1000)
                
            }
            
            
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
    
    /*func rotateAroundXAxis(angle: Double) -> [CLLocationCoordinate3D] {
        
        let simplifiedCoordinates = SwiftSimplify.simplify(self.coordinates, tolerance: self.simplifiedTolerance, highQuality: true)
        
        print("rotateAroundXAxis coordinates length" + String(simplifiedCoordinates.count))
        
        var newCoordinates = [CLLocationCoordinate3D]()
        
        newCoordinates.append(CLLocationCoordinate3D(longitude: simplifiedCoordinates[0].longitude, latitude: simplifiedCoordinates[0].latitude, altitude: altitude))
        
        for i in 1..<simplifiedCoordinates.count {
            newCoordinates.append(CLLocationCoordinate3D(longitude: simplifiedCoordinates[i].longitude, latitude: newCoordinates[i-1].latitude+(simplifiedCoordinates[i].latitude-simplifiedCoordinates[i-1].latitude)*cos(angle), altitude: newCoordinates[i-1].altitude+Float(GMSGeometryDistance(CLLocationCoordinate2D(latitude: simplifiedCoordinates[i].latitude, longitude: simplifiedCoordinates[i].longitude), CLLocationCoordinate2D(latitude: simplifiedCoordinates[i-1].latitude, longitude: simplifiedCoordinates[i].longitude))*sin(angle)*(((simplifiedCoordinates[i].latitude-simplifiedCoordinates[i-1].latitude)<0) ? -1:1))))
        }
        
        print(newCoordinates)
        
        return newCoordinates
    }*/
    
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
            statusLabel.text = "Status: Disconnected"
            batteryLabel.text = "Battery: n/a"
            altitudeLabel.text = "Altitude: n/a"
            satellitesLabel.text = "Satellites: n/a"
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
        
        // Setup the battery delegate
        let batt = (DJISDKManager.product() as! DJIAircraft).battery
        batt?.delegate = self
        
        // Setup the mission manager delegate
        missionManager.delegate = self
        
    }
    
    func product(_ product: DJIBaseProduct, connectivityChanged isConnected: Bool) {
        if isConnected {
            
            statusLabel.text = "Status: Connected"
            print("Product Connected")
            
        } else {
            
            statusLabel.text = "Status: Disconnected"
            batteryLabel.text = "Battery: n/a"
            altitudeLabel.text = "Altitude: n/a"
            satellitesLabel.text = "Satellites: n/a"
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
        
        altitudeLabel.text = "Altitude: " + String(state.altitude) + " m"
        
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

// MARK: DJIMissionManagerDelegate
extension ViewController: DJIMissionManagerDelegate {
    
    func missionManager(_ manager: DJIMissionManager, didFinishMissionExecution error: Error?) {
        
        if error != nil {
            
            print("Error completing mission: \(error)")
            
        } else {
            
            if finishedType == 0 {
            
                self.basicAlert(title: "Scribble Finished!", message: "Please take control of your aircraft.")
            
            } else {
                
                self.basicAlert(title: "Scribble Finished!", message: "Your aircraft will now return home and land automatically. You can cancel this action by toggling your flight mode switch or pressing the RTH button on your remote.")
                
            }
            
        }
        
    }
    
}


// MARK: DJIBatteryDelegate
extension ViewController : DJIBatteryDelegate {
    
    func battery(_ battery: DJIBattery, didUpdate batteryState: DJIBatteryState) {
        
        batteryLabel.text = "Battery: " + String(batteryState.batteryEnergyRemainingPercent) + "%"
        
    }
    
}

// MARK: GMSMapViewDelegate
extension ViewController : GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        
        // Get the marker index so we can update the coordinates array
        let index = marker.userData as! Int
        
        // Update the coordinate of the dropped marker
        simplifiedCoordinates[index] = marker.position
        
        print("Updating marker \(marker.userData) There are \(coordinates.count) coordinates after dragging")
        
        // Clear the map
        googleMapView.clear()
        
        // Redraw the path now that the marker has been moved
        addPathToMap(locations: simplifiedCoordinates)
 
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("Marker \(marker.userData)")
        print("You tapped at \(marker.position.latitude), \(marker.position.longitude)")
        
        currentlySelectedMarker = marker
        
        self.performSegue(withIdentifier: "waypointConfigSegue", sender: nil)
        
        return true
        
    }

}

extension ViewController : SimplifyPopoverViewControllerDelegate {
    
    func updateSimplifiedPath(tolerance: Float) {
        
        print("Tolerance is this: " + String(tolerance))
        
        self.simplifiedTolerance = tolerance
        
        googleMapView.clear()
        
        drawSimplifiedGooglePath(tolerance: tolerance)
        
    }
    
    // Store this so if the user opens the simplify popup we can set the value again
    func saveSimplifySliderValue(value: Float) {
        
        simplifySliderValue = value
        
    }
}

extension ViewController : MissionParamsViewControllerDelegate {
    
    func go(pathType: Int, altitude: Float, speed: Float, finishedType: Int) {
        
        self.pathType = pathType
        self.finishedType = finishedType
        self.missionAltitude = altitude
        self.speed = speed
        
        updateFlightTime()
        
        launchMission(pathType: pathType, altitude: altitude, speed: speed, finishedType: finishedType)
        
    }

}

extension ViewController: WaypointConfigViewControllerDelegate {
    
    // Change the altitude and delay for the specific waypoint
    func updateWaypointConfig(index: Int, altitude: Float, delay: Int) {
        print("Index \(index), altitude \(altitude), delay \(delay)")
        
        let waypoint: DJIWaypoint = waypointList[index]
        
        // If the altitude is different than the mission altitude or the delay is not zero then show it as orange
        if altitude != self.missionAltitude || delay != 0 {
            waypoint.altitude = altitude
            currentlySelectedMarker.icon = UIImage(named: "waypoint_modified")
        } else {
            waypoint.altitude = self.missionAltitude
            currentlySelectedMarker.icon = UIImage(named: "waypoint")
        }
        
        // Let's add a "stay" action if the delay is more than 0 seconds
        if delay > 0 {
            
            let action: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.stay, param: Int16(delay*1000))
            
            // Remove the action before we add a new one so we don't pile them up
            waypoint.removeAllActions()
            waypoint.add(action)
            
        }
        
        // If the waypoint has an existing action and the delay is set back to 0 let's remove it and reset the marker
        if waypoint.waypointActions.count > 0 && delay == 0 {
            
            currentlySelectedMarker.icon = UIImage(named: "waypoint")
            waypoint.removeAllActions()
            
        }
        
        // Update the estimated flight time as it needs to account for any waypoint delays
        updateFlightTime()
        
        
    }
    
}

