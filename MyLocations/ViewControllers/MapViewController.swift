//
//  MapViewController.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 14/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    // MARK:- outlets
    @IBOutlet weak var mapView: MKMapView!

    // MARK:- vars and lets
    var locations = [Location]()
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            self.managedObjectContextDidSet()
        }
    }

    // MARK:- view controller methods

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        updateLocations()
        if !locations.isEmpty {
            mapView.setRegion(region(for: locations), animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocationSegue" {
            if let controller = segue.destination as? LocationDetailsViewController {
                let locationIndex = sender as! Int
                controller.managedObjectContext = managedObjectContext
                controller.locationToEdit = locations[locationIndex]
            }
        }
    }

    // MARK:- methods

    func managedObjectContextDidSet() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: OperationQueue.main, using: {
                [weak self] notification in
                guard let self = self else { return }
                if !self.isViewLoaded { return }

                let userInfo = notification.userInfo
                if let inserted = userInfo?[NSInsertedObjectsKey] as? Set<Location> {
                    self.locations.append(contentsOf: inserted)
                    self.mapView.addAnnotations(inserted.filter({ _ in true}))
                }
                if let updated = userInfo?[NSUpdatedObjectsKey] as? Set<Location> {
                    for update in updated {
                        guard let index = self.locations.firstIndex(of: update) else { return }
                        self.locations[index] = update
                        self.mapView.removeAnnotation(update)
                        self.mapView.addAnnotation(update)
                    }
                }
                if let deleted = userInfo?[NSDeletedObjectsKey] as? Set<Location> {
                    for trashed in deleted {
                    guard let index = self.locations.firstIndex(of: trashed) else { return }
                    self.locations.remove(at: index)
                    self.mapView.removeAnnotation(trashed)
                    }
                }
        })
    }

    func updateLocations() {
        mapView.removeAnnotations(locations)
        let request = NSFetchRequest<Location>()
        request.entity = Location.entity()

        locations = (try? managedObjectContext.fetch(request)) ?? []
        mapView.addAnnotations(locations)
    }

    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
        let region: MKCoordinateRegion
        switch annotations.count {
        case 0:
            region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            return mapView.regionThatFits(region)
        case 1:
            region = MKCoordinateRegion(center: annotations.first!.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            return mapView.regionThatFits(region)
        default:
            // structs are value type unlike classes that are reference types
            var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)

            for annotation in annotations {
                topLeft.latitude = max(annotation.coordinate.latitude, topLeft.latitude)
                topLeft.longitude = min(annotation.coordinate.longitude, topLeft.longitude)

                bottomRight.latitude = min(annotation.coordinate.latitude, bottomRight.latitude)
                bottomRight.longitude = max(annotation.coordinate.longitude, bottomRight.longitude)
            }

            let center = CLLocationCoordinate2D(
                latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2,
                longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude) / 2)
            let padding = 1.1
            let span = MKCoordinateSpan(
                latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * padding, longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * padding)
            region = MKCoordinateRegion(center: center, span: span)
            return mapView.regionThatFits(region)
        }
    }

    // MARK:- actions
    @IBAction func showUserLocation(_ sender: UIBarButtonItem?) {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }

    @IBAction func showLocations(_ sender: UIBarButtonItem) {
        mapView.setRegion(region(for: locations), animated: true)
    }
}

// MARK:- map delegate extension
extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Location else {
            return nil
        }

        let identifier = "location"
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) else {
            let markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            markerView.canShowCallout = true
            markerView.isEnabled = true
            markerView.animatesWhenAdded = true
            markerView.tintColor = .systemPurple

            let button = UIButton(type: .detailDisclosure)
            button.tintColor = .systemPurple
            button.addTarget(self, action: #selector(locationPinTapped(_:)), for: .touchUpInside)
            if let index = locations.firstIndex(of: annotation as! Location) {
                button.tag = index
            }
            markerView.rightCalloutAccessoryView = button

            return markerView
        }

        annotationView.annotation = annotation
        let button = annotationView.rightCalloutAccessoryView as! UIButton
        if let index = locations.firstIndex(of: annotation as! Location) {
            button.tag = index
        }
        return annotationView
    }

    @objc func locationPinTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showLocationSegue", sender: sender.tag)
    }
}
