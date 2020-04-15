//
//  LocationsViewController.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 14/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import UIKit
import CoreData

class LocationsViewController: UITableViewController {

    // MARK:- vars and lets

    var managedObjectContext: NSManagedObjectContext!
    private lazy var fetchedResultController: NSFetchedResultsController<Location> = {
        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = Location.entity()
        let dateSort = NSSortDescriptor(key: "date", ascending: true)
        let categorySort = NSSortDescriptor(key: "category", ascending: true)
        fetchRequest.sortDescriptors = [categorySort, dateSort]
        fetchRequest.fetchBatchSize = 20
        let resultController = NSFetchedResultsController(
            fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "category", cacheName: "Locations")

        resultController.delegate = self
        return resultController
    }()

    deinit {
        // so that you don't recieve any more notifs when you don't need
        fetchedResultController.delegate = nil
    }

    // MARK:- view controller methods

    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
        navigationItem.leftBarButtonItem = editButtonItem
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editLocationSegue" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            if let cell = sender as? UITableViewCell,
                let path = tableView.indexPath(for: cell) {
                controller.locationToEdit = fetchedResultController.object(at: path)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections!.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultController.sections![section].name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return fetchedResultController.sections![section].numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell") as! LocationCell
        let location = fetchedResultController.object(at: indexPath)
        cell.configure(for: location)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let location = fetchedResultController.object(at: indexPath)
            location.deleteImage()
            managedObjectContext.delete(location)
            try? managedObjectContext.save()
        }
    }

    // MARK:- methods
    func loadData() {
        try? fetchedResultController.performFetch()
    }

}

// MARK:- NSFetchedResultsController delegates extension
extension LocationsViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .left)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        default:
            print(type)
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            // IndexSet(integer: sectionIndex) or [sectionIndex]
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections([sectionIndex], with: .automatic)
        default:
            print(type)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}
