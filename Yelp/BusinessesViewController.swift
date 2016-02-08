//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import JTProgressHUD

class BusinessesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIScrollViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

    var businesses: [Business]!
    var filterBusiness: [Business]!
    var searchBar = UISearchBar()
    var dismissKeyboardTap = UITapGestureRecognizer()
    var isMoreDataLoading = false
    var loadingMoreView: InfiniteScrollActivityView?
    var page = 1
    
    var locationManager : CLLocationManager!
    let yelpRed = UIColor(red: 202/255.0, green: 0.0, blue: 0.0, alpha: 1.0)

    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var yelpMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        
        searchBar.delegate = self
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar
        navigationController!.navigationBar.barTintColor = yelpRed
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Map", style: .Plain, target: self, action: "mapButton")
        navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()
        
        let frame = CGRectMake(0, tableView.contentSize.height, tableView.bounds.size.width, InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.hidden = true
        tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        tableView.contentInset = insets
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 200
        locationManager.requestWhenInUseAuthorization()
        yelpMapView.delegate = self

        Business.searchWithTerm(0, term: "Thai", completion: { (businesses: [Business]!, error: NSError!) -> Void in
            self.filterBusiness = businesses
            self.businesses = businesses
            self.tableView.reloadData()
            for business in businesses {
                print(business.name!)
                print(business.address!)
                self.addAnnotationAtCoordinate(CLLocationCoordinate2D(latitude: business.latitude!, longitude: business.longitude!), name: business.name!, term: business.categories!)
            }
        })


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filterBusiness != nil {
            return filterBusiness.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusinessCell", forIndexPath: indexPath) as! BusinessCell
        cell.business = filterBusiness[indexPath.row]
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("segue")
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
//        let movie = movies![indexPath!.row]
        let business = filterBusiness[(indexPath?.row)!]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
//        detailViewController.movie = movie
        detailViewController.business = business
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        yelpMapView.removeAnnotations(yelpMapView.annotations)
        if searchText.isEmpty {
            filterBusiness = businesses
        } else {
            Business.searchWithTerm(0, term: searchText, completion: { (businesses: [Business]!, error: NSError!) -> Void in
                self.filterBusiness = businesses
                self.tableView.reloadData()
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
                
                for business in businesses {
                    print(business.name!)
                    print(business.address!)
                    if let latitude = business.latitude {
                        if let categories = business.categories {
                            self.addAnnotationAtCoordinate(CLLocationCoordinate2D(latitude: latitude, longitude: business.longitude!), name: business.name!, term: categories)
                        }
                    }
                }
            })
        }
        
        
        
        tableView.reloadData()
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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (!isMoreDataLoading) {
            print("hello")
            // ... Code to load more results ...
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.dragging) {
                isMoreDataLoading = true
                let frame = CGRectMake(0, tableView.contentSize.height, tableView.bounds.size.width, InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                print("load more data")
                // ... Code to load more results ...
                
                Business.searchWithTerm(20 * page++, term: "Thai", completion: { (businesses: [Business]!, error: NSError!) -> Void in
                    for busi in businesses {
                        self.filterBusiness.append(busi)
                    }
                    
                    self.tableView.reloadData()
                    for business in businesses {
                        print(business.name!)
                        print(business.address!)
                    }
                    self.loadingMoreView!.stopAnimating()
                    self.isMoreDataLoading = false

                })
                
            }
        }
    }
    
    func mapButton() {
        UIView.transitionFromView(tableView, toView: yelpMapView, duration: 1.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft, UIViewAnimationOptions.ShowHideTransitionViews ], completion: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "List", style: .Plain, target: self, action: "listButton")
        navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()
    }
    
    
    func listButton(){
        UIView.transitionFromView(yelpMapView, toView: tableView, duration: 1.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft, UIViewAnimationOptions.ShowHideTransitionViews ], completion: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Map", style: .Plain, target: self, action: "mapButton")
        navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()
    }
    
    
    func goToLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(location.coordinate, span)
        yelpMapView.setRegion(region, animated: false)
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
            yelpMapView.setRegion(region, animated: false)
        }
    }
    
    func addAnnotationAtCoordinate(coordinate: CLLocationCoordinate2D, name: String, term: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = name
        annotation.subtitle = term
        yelpMapView.addAnnotation(annotation)
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
            //return nil so map draws default view for it (eg. blue dot)...
            return nil
        }
        
        let identifier = "customAnnotationView"
        
        // custom image annotation
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if (annotationView == nil) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        }
        else {
            annotationView!.annotation = annotation
        }
        print("=========")
        print(annotationView?.image)
        annotationView!.image = UIImage(named: "pinsmall")
        annotationView?.tintColor = yelpRed
        return annotationView
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
