//
//  LocationCell.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 14/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell {

    // MARK:- outlets

    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(for location: Location) {
        descriptionLabel.text = location.title
        addressLabel.text = location.placemark == nil
            ? String(format: "Lat: %.8f, Long: %.8f", location.latitude, location.longitude)
            : String.fromPlacemark(placemark: location.placemark!, multiline: false)

        guard let image = location.image else {
            locationImageView.image = UIImage(named: "No Photo")
            return
        }
//        imageView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 10, height: 10))
//        imageView.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: 10, height: 10))
        locationImageView.image = image.resized(withBounds: CGSize(width: 52, height: 52))
        locationImageView.layer.cornerRadius = locationImageView.bounds.size.width / 2
        locationImageView.clipsToBounds = true
    }

}
