//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 13/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {

    // MARK:- IBOutlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!

    // MARK:- constants and variables
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var isUpdatingLocation = false
    var lastLocationError: Error?
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var isGeocoding = false
    var lastGeocodeError: Error?
    var timer: Timer?

    // MARK:- view controller methods

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK:- navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "locationDetailSegue" {
            if let controller = segue.destination as? LocationDetailsViewController {
                controller.placemark = placemark
                controller.coordinates = location!.coordinate
            }
        }
    }

    // MARK:- location delegates

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        guard nsError.code != CLError.locationUnknown.rawValue else {
            return
        }
        lastLocationError = error
        stopLocationUpdates()
        updateUI()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        // the timeInterval must be more than more than -5 seconds eg: 0, which will mean the location was picked "right now"
        // timeIntervalSinceNow always returns a negative # meaning it's in the past
        guard newLocation.timestamp.timeIntervalSinceNow > -5 else { return }
        // having an acuracy less than zero makes this location invalid
        guard newLocation.horizontalAccuracy > 0 else { return }
        // NB: smaller horizontalAccuracy means better accuracy
        guard location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy else { return }

        lastLocationError = nil
        location = locations.last

        guard newLocation.horizontalAccuracy <= locationManager.desiredAccuracy else { return }
        stopLocationUpdates()
        doGeocode(for: location!, onComplete: geocodeOnComplete)
        updateUI()
    }

    // MARK:- member methods

    func showLocationError() {
        let alert = UIAlertController(title: "Location Access Disabled", message: "Please enable location access for this app in settings", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func doGeocode(for location: CLLocation, onComplete handler: @escaping ([CLPlacemark]?, Error?) -> ()) {
        if isGeocoding {
            geocoder.cancelGeocode()
        }
        geocoder.reverseGeocodeLocation(location, completionHandler: handler)
    }

    func geocodeOnComplete(placemarks: [CLPlacemark]?, error: Error?) {
        isGeocoding = false
        guard let placemarks = placemarks,
            !placemarks.isEmpty,
            error == nil else {
                placemark = nil
                lastGeocodeError = error
                updateUI()
                return
        }
        placemark = placemarks.last
        updateUI()
    }

    func didTimeOut(_ timer: Timer) {
        if location == nil {
            stopLocationUpdates()
            lastLocationError = NSError(domain: "MyErrorDomain", code: 1, userInfo: nil)
            updateUI()
            return
        }
        stopLocationUpdates()
        doGeocode(for: location!, onComplete: geocodeOnComplete)
        updateUI()
    }

    func startLocationUpdates() {
        guard !CLLocationManager.locationServicesEnabled() else {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            isUpdatingLocation = true
            location = nil
            lastLocationError = nil
            timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false, block: didTimeOut)
            return
        }

        showLocationError()
    }

    func stopLocationUpdates() {
        if isUpdatingLocation {
            locationManager.stopUpdatingLocation()
            isUpdatingLocation = false
            locationManager.delegate = nil
            if let timer = timer {
                timer.invalidate()
            }
        }
    }

    func updateUI() {
        if let placemark = placemark {
            addressLabel.text = String.fromPlacemark(placemark: placemark)
        } else if isGeocoding { addressLabel.text = "Searching for Address..."
        } else if lastGeocodeError != nil { addressLabel.text = "Error Finding Address"
        } else {
            addressLabel.text = "No Address Found" }

        guard let location = location else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            tagButton.isHidden = true
            addressLabel.text = ""

            let status: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    status = "Location access denied"
                } else {
                    status = "Unable to get location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                status = "Location service disabled"
            } else if isUpdatingLocation {
                status = "Searching..."
            } else {
                status = "Tap 'Get Location' button to start"
            }
            messageLabel.text = status
            configureGetButton()
            return
        }

        latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
        messageLabel.text = "Found location"
        tagButton.isHidden = false
        configureGetButton()
    }

    func configureGetButton() {
        let title = isUpdatingLocation ? "Stop" : "Get Location"
        getButton.setTitle(title, for: .normal)
        getButton.tintColor = isUpdatingLocation ? .systemRed : .systemPurple
    }

    // MARK:- IBActions
    @IBAction func tagLocation(_ sender: UIButton) {
    }

    @IBAction func getLocation(_ sender: UIButton) {
        guard !isUpdatingLocation else {
            location = nil
            lastLocationError = nil
            lastGeocodeError = nil
            placemark = nil
            stopLocationUpdates()
            updateUI()
            return
        }
        let permisionStatus = CLLocationManager.authorizationStatus()
        if permisionStatus == .denied ||  permisionStatus == .notDetermined || permisionStatus == .restricted {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        startLocationUpdates()
        updateUI()
    }
}
