//
//  LocationCell.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 14/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(for location: Location) {
        textLabel?.text = location.locationDescription.isEmpty ? "No Description" : location.locationDescription
        detailTextLabel?.text = location.placemark == nil
            ? String(format: "Lat: %.8f, Long: %.8f", location.latitude, location.longitude)
            : String.fromPlacemark(placemark: location.placemark!, multiline: false)

        if let image = location.image {
            imageView?.image = image.resized(withBounds: CGSize(width: 60, height: 60))
        }
    }

}
