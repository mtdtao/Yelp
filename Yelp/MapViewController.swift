//
//  MapViewController.swift
//  Yelp
//
//  Created by ZengJintao on 2/2/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import JTProgressHUD

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var searchBar = UISearchBar()
    var dismissKeyboardTap = UITapGestureRecognizer()
    
    var locationManager : CLLocationManager!
    var businesses: [Business]!
    var filterBusiness: [Business]!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
//        let centerLocation = CLLocation(latitude: 37.7833, longitude: -122.4167)
//        goToLocation(centerLocation)
        //let coord = CLLocationCoordinate2D(latitude: 37.7833, longitude: -122.4167)
        //addAnnotationAtCoordinate(coord)
        
        searchBar.delegate = self
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar
        navigationController!.navigationBar.barTintColor = UIColor.redColor()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 200
        locationManager.requestWhenInUseAuthorization()
        
        Business.searchWithTerm(0, term: "Thai", completion: { (businesses: [Business]!, error: NSError!) -> Void in
            if error == nil {
                self.filterBusiness = businesses
                self.businesses = businesses
                for business in businesses {
                    print(business.name!)
                    print(business.address!)
                    self.addAnnotationAtCoordinate(CLLocationCoordinate2D(latitude: business.latitude!, longitude: business.longitude!), name: business.name!, term: business.categories!)
                }
            } else {
               
            }
            
        })
        
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goToLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(location.coordinate, span)
        mapView.setRegion(region, animated: false)
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.1, 0.1)
            let region = MKCoordinateRegionMake(location.coordinate, span)
            mapView.setRegion(region, animated: false)
        }
    }

    func addAnnotationAtCoordinate(coordinate: CLLocationCoordinate2D, name: String, term: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = name
        annotation.subtitle = term
        mapView.addAnnotation(annotation)
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "customAnnotationView"
        
        // custom image annotation
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if (annotationView == nil) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        else {
            annotationView!.annotation = annotation
        }
        annotationView!.image = UIImage(named: "pin")
        
        return annotationView
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        JTProgressHUD.showWithStyle(.Gradient)
        dismissKeyboard()
        mapView.removeAnnotations(mapView.annotations)
        if searchBar.text == nil {
            
        } else {
            
            Business.searchWithTerm(0, term: searchBar.text!, completion: { (businesses: [Business]!, error: NSError!) -> Void in
                if error == nil {
                    self.filterBusiness = businesses
                    self.businesses = businesses
                    for business in businesses {
                        print(business.name!)
                        print(business.address!)
                        self.addAnnotationAtCoordinate(CLLocationCoordinate2D(latitude: business.latitude!, longitude: business.longitude!), name: business.name!, term: business.categories!)
                    }
                JTProgressHUD.hide()
                } else {
                    self.delay(2, closure: {
                        JTProgressHUD.hide()
                    })
                }
            })
            
        }
        
       
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        dismissKeyboardTap = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        self.view.addGestureRecognizer(dismissKeyboardTap)
        return true
    }
    
    func dismissKeyboard() {
        self.searchBar.resignFirstResponder()
        self.view.removeGestureRecognizer(dismissKeyboardTap)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
