//
//  AppDelegate.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 13/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // MARK: - Core Data stack
    // the stack is made of;
    // 1. an NSManagedObjectModel from the model file created
    // 2. an NSPersistentStoreCoordinator which manages the SQLite database
    // 3. and NSManagedObjectContext which is what you use to talk to core data
    // all these are packed into NSPersistentContainer
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores {
            (containerDescription, error) in
            if let error = error as NSError? {
                fatalError("error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    lazy var managedObjectContext: NSManagedObjectContext = persistentContainer.viewContext

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let tabController = window?.rootViewController as? UITabBarController
        let navController = tabController?.viewControllers?.first as? UINavigationController
        let currentLocationViewController = navController?.viewControllers.first as? CurrentLocationViewController
        currentLocationViewController?.managedObjectContext = managedObjectContext

        let secondPage = tabController?.viewControllers?[1] as? UINavigationController
        let locationsViewController = secondPage?.viewControllers.first as? LocationsViewController
        locationsViewController?.managedObjectContext = managedObjectContext
        let _ = locationsViewController?.view // to init the table view. else updates to the model when the view is not initialized will not appear in the view when it's finally initialized (when using NSFetchedResultsControllerDelegate)

        let thirdPage = tabController?.viewControllers?[2] as? UINavigationController
        let mapViewController = thirdPage?.viewControllers.first as? MapViewController
        mapViewController?.managedObjectContext = managedObjectContext
//        let _ = mapViewController?.view

        listenForDataErrors()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveContext()
    }

    // MARK:- methods

    func listenForDataErrors() {
       NotificationCenter.default.addObserver(
            forName: dataSaveFailedNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { [weak self]
                notification in
                let message = """
Something went wrong while saving your data.
Contact us to report this issue.

Sorry for this inconvinience.
"""
                let alert = UIAlertController(title: "Ooops", message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    let exception = NSException(name: NSExceptionName.internalInconsistencyException, reason: "Save operation failed", userInfo: nil)
                    exception.raise()

                })
                alert.addAction(action)

                self?.window?.rootViewController?.present(alert, animated: true, completion: nil)
        })
    }

    // MARK: Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }
}

