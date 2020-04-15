//
//  Location+CoreDataClass.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 14/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

@objc(Location)
public class Location: NSManagedObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var title: String? {
        return !locationDescription.isEmpty ? locationDescription : "No Description"
    }

    public var subtitle: String? {
        return category
    }

    var image: UIImage? {
        guard let imagePath = imageURL,
        let data = try? Data(contentsOf: appDocumentDirectory.appendingPathComponent(imagePath)),
            let img = UIImage(data: data) else { return nil }
        return img
    }

    func deleteImage() {
        if let imageURL = imageURL {
             try? FileManager.default.removeItem(at: appDocumentDirectory.appendingPathComponent(imageURL))
        }
    }

}
