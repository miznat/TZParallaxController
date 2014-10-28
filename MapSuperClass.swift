//
//  MapSuperClass.swift
//  betaTable
//
//  Created by Tanzim on 23/07/2014.
//  Copyright (c) 2014 ikhlas. All rights reserved.
//


import UIKit
import MapKit

let SCREEN_HEIGHT_WITHOUT_STATUS_BAR      = UIScreen.mainScreen().bounds.size.height - 20
let SCREEN_WIDTH                          = UIScreen.mainScreen().bounds.size.width
let HEIGHT_STATUS_BAR: Float              = 20.0
let Y_DOWN_TABLEVIEW                      = SCREEN_HEIGHT_WITHOUT_STATUS_BAR - 40
let DEFAULT_HEIGHT_HEADER: CGFloat        = (UIScreen.mainScreen().bounds.size.height)/3 // height of the map
let MIN_HEIGHT_HEADER: CGFloat            = 10.0
let DEFAULT_Y_OFFSET: CGFloat             = (UIScreen.mainScreen().bounds.size.height == 480.0) ? -200.0 : -250.0
let FULL_Y_OFFSET: CGFloat                = -200.0
let MIN_Y_OFFSET_TO_REACH                 = -30
let OPEN_SHUTTER_LATITUDE_MINUS: CGFloat  = 0.005
let CLOSE_SHUTTER_LATITUDE_MINUS: CGFloat = 0.018

protocol MapSuperClassDelegate {
    // Tap handlers
    func didTapOnMapView()
    func didTapOnTableView()
    
    // TableView's move
    func didTableViewMoveDown()
    func didTableViewMoveUp()
}


class MapSuperClass: UIViewController, UITableViewDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate, UITableViewDataSource {
    var delegate    : MapSuperClassDelegate?
    var tableView   : UITableView?
    var mapView     : MKMapView?
    //var dataSource  : UITableViewDataSource!
    
    let heighTableViewHeader       = DEFAULT_HEIGHT_HEADER
    let heighTableView             = SCREEN_HEIGHT_WITHOUT_STATUS_BAR
    let widthTableView             = SCREEN_WIDTH
    let minHeighTableViewHeader    = MIN_HEIGHT_HEADER
    let default_Y_tableView        = HEIGHT_STATUS_BAR
    let Y_tableViewOnBottom        = Y_DOWN_TABLEVIEW
    let minYOffsetToReach          = MIN_Y_OFFSET_TO_REACH
    let latitudeUserUp             = CLOSE_SHUTTER_LATITUDE_MINUS
    let latitudeUserDown           = OPEN_SHUTTER_LATITUDE_MINUS
    let default_Y_mapView          = DEFAULT_Y_OFFSET
    let headerYOffSet              = DEFAULT_Y_OFFSET
    let heightMap: Float           = 1000.0
    let regionAnimated             = true
    let userLocationUpdateAnimated = true
    
    var tapMapViewGesture   : UITapGestureRecognizer?
    var tapTableViewGesture : UITapGestureRecognizer?
    var isShutterOpen       : Bool = false
    var displayMap          : Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupMapView()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Set all view we will need
    func setupTableView() {
        self.tableView = UITableView(frame: CGRectMake(0, 20, self.widthTableView, self.heighTableView))
        self.tableView!.tableHeaderView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, CGFloat(self.heighTableViewHeader)))
        self.tableView!.backgroundColor = UIColor.clearColor()
        
        // Add gesture to gestures
        self.tapMapViewGesture = UITapGestureRecognizer(target: self, action: "handleTapMapView:")
        self.tapTableViewGesture = UITapGestureRecognizer(target: self, action: "handleTapTableView:")
        self.tapTableViewGesture!.delegate = self
        self.tableView!.tableHeaderView?.addGestureRecognizer(self.tapMapViewGesture!)
        self.tableView!.addGestureRecognizer(self.tapTableViewGesture!)
        
        // Init selt as default tableview's delegate & datasource
        self.tableView!.delegate = self
        self.tableView!.dataSource = self
        self.view.addSubview(self.tableView!)
    }
    
    func setupMapView() {
        
        
        self.mapView = MKMapView(frame: CGRectMake(0, self.default_Y_mapView, self.widthTableView, self.heighTableView))
        self.mapView!.showsUserLocation = true
        self.mapView!.delegate = self
        
        self.mapView!.showsPointsOfInterest = false // Hide other venues from map
        
        self.view.insertSubview(self.mapView!, belowSubview: self.tableView!)
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // Internal Methods
    func handleTapMapView(gesture: UIGestureRecognizer) {
        if !self.isShutterOpen {
            // Move the tableView down to let the map appear entirely
            self.openShutter()
            
            // Inform the delegae
            self.delegate?.didTapOnMapView()
        }
    }
    
    func handleTapTableView(gesture: UIGestureRecognizer) {
        if self.isShutterOpen {
            // Move the tableView up to reach is origin position
            self.closeShutter()
            
            // Inform the delegate
            self.delegate?.didTapOnTableView()
        }
    }
    // Move DOWN the tableView to show the "entire" mapView
    func openShutter() {
        UIView.animateWithDuration(
            0.2,
            delay: 0.1,
            options: .CurveEaseOut,
            animations: { () -> Void in
                self.tableView!.tableHeaderView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.minHeighTableViewHeader))
                self.mapView!.frame = CGRectMake(0, FULL_Y_OFFSET, CGFloat(self.mapView!.frame.size.width), CGFloat(self.heightMap))
                self.tableView!.frame = CGRectMake(0, self.Y_tableViewOnBottom, self.tableView!.frame.size.width, self.tableView!.frame.size.height)
            },
            completion: {
                (finished: Bool) -> Void in
                // Disable cells selection
                self.tableView!.allowsSelection = false
                self.isShutterOpen = true
                self.tableView!.scrollEnabled = false
                
                // Center the user 's location
                self.extraZoomToUserLocation(userLocationInfo: self.mapView!.userLocation, minmumLatitude: Float(self.latitudeUserDown), animated: self.regionAnimated)
                
                // Inform the delegate
                self.delegate?.didTableViewMoveDown()
            }
        )
    }
    
    func closeShutter() {
        UIView.animateWithDuration(
            0.2,
            delay: 0.1,
            options: .CurveEaseOut,
            animations: { () -> Void in
                self.tableView!.tableHeaderView = UIView(frame: CGRectMake(0, self.headerYOffSet, self.view.frame.size.width, self.heighTableViewHeader))
                self.mapView!.frame = CGRectMake(0, self.default_Y_mapView, self.mapView!.frame.size.width, self.heighTableView)
                self.tableView!.frame = CGRectMake(0, CGFloat(self.default_Y_tableView), self.tableView!.frame.size.width, self.tableView!.frame.size.height)
            },
            completion: {
                (finished: Bool) -> Void in
                // Enable cells selection
                self.tableView!.allowsSelection = true
                self.isShutterOpen = false
                self.tableView!.scrollEnabled = true
                self.tableView!.tableHeaderView?.addGestureRecognizer(self.tapMapViewGesture!)
                
                // Center the user 's location
                self.zoomToUserLocation(userLocationInfo: self.mapView!.userLocation, minmumLatitude: Float(self.latitudeUserUp), animated: self.regionAnimated)
                
                // Inform the delegate
                self.delegate?.didTableViewMoveUp()
            }
        )
        
    }
    
    // UITableViewDelegate Methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var scrollOffset = scrollView.contentOffset.y
        var headerMapViewFrame = self.mapView!.frame
        
        if scrollOffset < 0 {
            // Adjust map
            headerMapViewFrame.origin.y = self.headerYOffSet - (scrollOffset / 2)
        } else {
            // Scrolling Up -> normal behavior
            headerMapViewFrame.origin.y = self.headerYOffSet - scrollOffset
        }
        self.mapView!.frame = headerMapViewFrame
        
        // check if the Y offset is under the minus Y to reach
        if self.tableView!.contentOffset.y < CGFloat(self.minYOffsetToReach) {
            if !self.displayMap {
                self.displayMap = true
            }
        } else {
            if self.displayMap {
                self.displayMap = false
            }
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.displayMap == true {
            self.openShutter()
        }
    }
    
    
    // MapView Delegate Methods
    func zoomToUserLocation(userLocationInfo userLocation: MKUserLocation!, minmumLatitude minLatitude: Float, animated anim: Bool) {
        if userLocation.location == nil {
            return
        }
        
        var loc = userLocation.location.coordinate
        loc.latitude = loc.latitude - CLLocationDegrees(minLatitude)
        
        var region = MKCoordinateRegion(center: loc, span: MKCoordinateSpanMake(0.1, 0.1))    //Zoom distance
        region = self.mapView!.regionThatFits(region)
        self.mapView!.setRegion(region, animated: anim)
        
    }
    
    
    // MapView Delegate Methods
    func extraZoomToUserLocation(userLocationInfo userLocation: MKUserLocation!, minmumLatitude minLatitude: Float, animated anim: Bool) {
        if userLocation.location == nil {
            return
        }
        
        var loc = userLocation.location.coordinate
        
        loc.latitude = loc.latitude - CLLocationDegrees(minLatitude)
        
        var region = MKCoordinateRegion(center: loc, span: MKCoordinateSpanMake(0.03, 0.03))    //Zoom distance
        region = self.mapView!.regionThatFits(region)
        self.mapView!.setRegion(region, animated: anim)
    }
    
    
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        if isShutterOpen == true {
            
            //            self.zoomToUserLocation(userLocationInfo: self.mapView!.userLocation, minmumLatitude: self.latitudeUserDown, animated: self.userLocationUpdateAnimated)
            //
        } else {
            
            self.zoomToUserLocation(userLocationInfo: self.mapView!.userLocation, minmumLatitude: Float(self.latitudeUserUp), animated: self.userLocationUpdateAnimated)
        }
    }
    
    // UIGestureRecognizer Delegate Methods
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldReceiveTouch touch: UITouch!) -> Bool {
        if gestureRecognizer == self.tapTableViewGesture {
            return self.isShutterOpen
        }
        
        return true
    }
    
    
    
    
    // UITableViewDataSource Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    
    
    func tableView(tableView:UITableView!, heightForRowAtIndexPath indexPath:NSIndexPath)->CGFloat {
        
        return 80
        
    }
    
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var identifier : NSString
        if indexPath.row == 0 {
            identifier = "firstCell"
            // Add some shadow to the first cell
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
            
            if !(cell != nil) {
                cell = UITableViewCell(style: .Default, reuseIdentifier: identifier)
                
                cell!.layer.shadowPath = UIBezierPath(rect: cell!.layer.bounds).CGPath
                cell!.layer.shadowOffset = CGSizeMake(-2, -2)
                cell!.layer.shadowColor = UIColor.grayColor().CGColor
                cell!.layer.shadowOpacity = 0.75
            }
            cell?.textLabel.text = "Hello World !"
            
            return cell!
            
        } else {
            var identifier = "otherCell"
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
            if !(cell != nil) {
                cell = UITableViewCell(style: .Default, reuseIdentifier: identifier)
            }
            cell?.textLabel.text = "Hello World !"
            
            return cell!
            
            
        }
        
        
    }
    
    
    
    func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        //first get total rows in that section by current indexPath.
        var totalRow = tableView.numberOfRowsInSection(indexPath.section)
        
        //this is the last row in section.
        if indexPath.row == totalRow - 1 {
            // get total of cells's Height
            var cellsHeight = Float(totalRow) * Float(cell.frame.size.height)
            // calculate tableView's Height with it's the header
            var s = tableView.tableHeaderView?.frame.size.height
            var tableHeight = Float(tableView.frame.size.height) - Float(s!)//Float(tableView.tableHeaderView?.frame.size.height)
            
            // Check if we need to create a foot to hide the backView (the map)
            if (cellsHeight - Float(tableView.frame.origin.y)) < tableHeight {
                // Add a footer to hide the background
                tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, 320, CGFloat(tableHeight - cellsHeight)))
                tableView.tableFooterView?.backgroundColor = UIColor.whiteColor()
            }
        }
        
    }
    
    
}
