//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 13/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {

    // MARK:- IBOutlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var latitudeTextLable: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var containerView: UIView!

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
    // MARK: core data
    var managedObjectContext: NSManagedObjectContext!
    var isLogoVisible = false
    var soundID: SystemSoundID = 0
    lazy var logoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Logo"), for: .normal)
        button.sizeToFit()
        button.center.x = self.view.bounds.midX
        button.center.y = self.view.bounds.midY
        button.addTarget(self, action: #selector(getLocation), for: .touchUpInside)
        return button
    }()

    // MARK:- view controller methods

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSounds("Sound.caf")
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
                controller.managedObjectContext = managedObjectContext
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
//        updateUI()
    }

    // MARK:- animation delegate

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        view.layer.removeAllAnimations()
    }

    // MARK:- Sound effects

    func loadSounds(_ name: String) {
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            let filePath = URL(fileURLWithPath: path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(filePath as CFURL, &soundID)
            if error != kAudioServicesNoError {
                print(error)
            }
        }
    }

    func unloadSounds() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }

    func playSound() {
        AudioServicesPlaySystemSound(soundID)
    }

    // MARK:- member methods

    func showLogoButton() {

        guard !isLogoVisible else { return }
        startFadeTransition()
        isLogoVisible = true
        containerView.isHidden = true
        view.addSubview(logoButton)
    }

    func hideLogoButton() {
        guard isLogoVisible else { return }
        startFadeTransition()
        isLogoVisible = false
        logoButton.removeFromSuperview()
        containerView.isHidden = false
    }

    func startFadeTransition() {
        let transition = CATransition()
        transition.type = .fade
        transition.timingFunction = CAMediaTimingFunction(name: .easeIn)
        view.layer.add(transition, forKey: nil)
    }

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
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                updateUI()
                return
        }
        playSound()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        placemark = placemarks.last
        updateUI()
    }

    func didTimeOut(_ timer: Timer) {
        guard let location = location else {
            stopLocationUpdates()
            lastLocationError = NSError(domain: "MyErrorDomain", code: 1, userInfo: nil)
            updateUI()
            return
        }
        stopLocationUpdates()
        doGeocode(for: location, onComplete: geocodeOnComplete)
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

        longitudeTextLabel.isHidden = location == nil
        latitudeTextLable.isHidden = location == nil
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
                status = "Tap the logo to start"
                showLogoButton()
            }
            messageLabel.text = status
            configureResetButton()
            return
        }

        latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
        messageLabel.text = "Found location"
        tagButton.isHidden = false
        configureResetButton()
    }

    func configureResetButton() {
        let title = isUpdatingLocation ? "Stop" : "Reset"
        resetButton.setTitle(title, for: .normal)
        resetButton.tintColor = isUpdatingLocation ? .systemRed : .systemPurple
        resetButton.isHidden = location == nil && !isUpdatingLocation
        let spinnerTag = 1000
        if isUpdatingLocation {
            guard let _ = view.viewWithTag(spinnerTag) as? UIActivityIndicatorView else {
                let spinner: UIActivityIndicatorView
                if #available(iOS 13, *) {
                    spinner = UIActivityIndicatorView(style: .large)
                } else {
                    spinner = UIActivityIndicatorView(style: .gray)
                }
                spinner.tag = spinnerTag
                spinner.center = messageLabel.center
                spinner.center.y = spinner.bounds.size.height / 2 + 25
                spinner.startAnimating()
                containerView.addSubview(spinner)
                return
            }
        } else {
            guard let spinner = view.viewWithTag(spinnerTag) as? UIActivityIndicatorView else { return }
            spinner.stopAnimating()
            spinner.removeFromSuperview()
        }
    }

    // MARK:- IBActions
    @IBAction func tagLocation(_ sender: UIButton) {
    }

    @objc func getLocation(_ sender: UIButton) {
        let permisionStatus = CLLocationManager.authorizationStatus()
        if permisionStatus == .denied ||  permisionStatus == .notDetermined || permisionStatus == .restricted {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        hideLogoButton()
        startLocationUpdates()
        updateUI()
    }

    @IBAction func reset(_ sender: UIButton) {
        location = nil
        lastLocationError = nil
        lastGeocodeError = nil
        placemark = nil
        stopLocationUpdates()
        updateUI()
    }
}
