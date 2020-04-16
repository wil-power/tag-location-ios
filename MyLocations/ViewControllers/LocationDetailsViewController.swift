//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 13/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class LocationDetailsViewController: UITableViewController {

    // MARK:- iboutlets
    @IBOutlet weak var descriptionField: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var addPhotoLabel: UILabel!
    @IBOutlet weak var imageCell: UITableViewCell!
    @IBOutlet weak var imageView: UIImageView!

    // MARK:- vars and lets
    var image: UIImage?
    var coordinates = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var date = Date()
    var locationToEdit: Location? {
        // code in this block is executed immidiately you set the value of this var
        didSet {
            if let location = locationToEdit {
                coordinates = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                placemark = location.placemark
                date = location.date
            }
        }
    }
    // MARK: core data
    var managedObjectContext: NSManagedObjectContext!

    // MARK:- viewcontroller methods
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        listenForDidEnterBackground()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initUpdateImage()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "categorySegue" {
            if let navController = segue.destination as? UINavigationController,
                let controller = navController.topViewController as? CategoryViewController {
                controller.selectedCategory = categoryLabel.text!
            }
        }
    }

    // MARK:- table methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = image, section == 0 {
            return 2
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let image = image,
            indexPath.section == 0,
            indexPath.row == 0 else { return super.tableView(tableView, cellForRowAt: indexPath) }
        imageView.image = image
        return imageCell
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let _ = image, indexPath.section == 0, indexPath.row == 0 {
            return 176
        } else if indexPath.section == 1 && indexPath.row == 0 {
            return 88
        } else {
            return 54
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath.section == 2 ? nil : indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0 {
            descriptionField.becomeFirstResponder()
        } else if image == nil && indexPath.section == 0 && indexPath.row == 0 {
            prepNshowImagePicker()
        } else if image != nil && indexPath.section == 0 && indexPath.row == 1 {
            prepNshowImagePicker()
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            image = nil
            tableView.deleteRows(at: [indexPath], with: .automatic)
            addPhotoLabel.text = "Add Photo"
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return image != nil && indexPath.section == 0 && indexPath.row == 0
    }

    // MARK:- methods

    func listenForDidEnterBackground() {
        NotificationCenter.default.addObserver(
        forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.descriptionField.resignFirstResponder()
            if self?.presentedViewController != nil {
                self?.dismiss(animated: false, completion: nil)
            }
        }
    }

    func initUI() {
        if let _ = locationToEdit {
            navigationItem.title = "Update Tag"
        }
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        latitudeLabel.text = String(format: "%.8f",  coordinates.latitude)
        longitudeLabel.text = String(format: "%.8f",  coordinates.longitude)
        addressLabel.text = placemark != nil ? String.fromPlacemark(placemark: placemark!) : "N/A"
        dateLabel.text = String.fromDate(date: date)
        categoryLabel.text = locationToEdit?.category ?? "No Category"
        descriptionField.text = locationToEdit?.locationDescription ?? ""
    }

    @objc func hideKeyboard(_ sender: UIGestureRecognizer) {
        let point = sender.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        guard let path = indexPath, !(path.section == 1 && path.row == 0) else { return }
        descriptionField.resignFirstResponder()
    }

    // MARK:- ibactions
    @IBAction func done(_ sender: UIBarButtonItem) {
        let location = locationToEdit != nil ? locationToEdit! : Location(context: managedObjectContext)
        location.category = categoryLabel.text!
        location.locationDescription = descriptionField.text!
        location.date = date
        location.placemark = placemark
        location.longitude = coordinates.longitude
        location.latitude = coordinates.latitude
        if let image = image {
            location.imageURL = "\(location.date.timeIntervalSince1970).JPEG"
            saveImage(image, for: location)
        }
        do {
            try managedObjectContext.save()
        } catch {
            fatalDataError(error)
        }
        let hud = HudView.hud(inView: navigationController!.view, animated: true)
        hud.text = locationToEdit != nil ? "Updated" : "Tagged"
        navigationController?.popViewController(animated: true)
        afterDelay(0.7) {
            hud.hide()
        }
    }
    
    // this is a target action for a rewind segue. Rewind segue "rewinds" a segue so a segue to categoryViewController will rewind back to this controller
    // rewind segue is a simpler alternative for picker screens compared to delegates
    @IBAction func pickedCategory(_ segue: UIStoryboardSegue) {
        let controller = segue.source as! CategoryViewController
        categoryLabel.text = controller.selectedCategory
    }
}

// MARK:- image fuctionalities
extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: photo picker methods

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        guard let editedImage = info[.editedImage] as? UIImage else { return }
        let imagePath = IndexPath(row: 0, section: 0)
        if image == nil {
            image = editedImage
            addPhotoLabel.text = "Update Photo"
            tableView.insertRows(at: [imagePath], with: .automatic)
        } else {
            image = editedImage
            imageView.image = editedImage
        }
    }

    func initUpdateImage() {
        guard tableView.numberOfRows(inSection: 0) == 1 else { return }
        if let location = locationToEdit,
            let img = location.image {
            image = img
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            addPhotoLabel.text = "Update Photo"
        }
    }

    func prepNshowImagePicker() {

        let alert = UIAlertController(title: "Photo Source", message: "Select where you want to pick a picture", preferredStyle: .actionSheet)
        let photosAction = UIAlertAction(title: "Photo Library", style: .default) {
            _ in
            self.showImagePicker(sourceType: .photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) {
                _ in
                self.showImagePicker(sourceType: .camera)
            }
            alert.addAction(cameraAction)
        }
        alert.addAction(photosAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.view.tintColor = .systemPurple
        present(imagePicker, animated: true, completion: nil)
    }

    func saveImage(_ image: UIImage, for location: Location) {
        do {
            try image.jpegData(compressionQuality: 0.5)?.write(to: appDocumentDirectory.appendingPathComponent(location.imageURL!), options: .atomic)
        } catch {
            fatalDataError(error)
        }
    }
}
