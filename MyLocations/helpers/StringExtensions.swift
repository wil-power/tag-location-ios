//
//  StringExtensions.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 13/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import Foundation
import CoreLocation

// global variables like this are already lazily initialized
private let dateFormatter: DateFormatter = {
    let dateformatter = DateFormatter()
    dateformatter.dateStyle = .medium
    dateformatter.timeStyle = .short
    return dateformatter
}()

extension String {
    static func fromPlacemark(placemark: CLPlacemark, multiline: Bool = true) -> String {

        var line1 = ""

        if let s = placemark.subThoroughfare {
            line1 += s + " "
        }

        if let s = placemark.thoroughfare {
            line1 += s }

        guard multiline else {
            if let s = placemark.locality {
                line1 += " " + s
            }
            return line1
        }

        var line2 = ""
        if let s = placemark.locality {
            line2 += s + " "
        }
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        if let s = placemark.postalCode {
            line2 += s }

        return line1 + "\n" + line2
    }

    static func fromDate(date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {

        if dateFormatter.dateStyle != dateStyle {
            dateFormatter.dateStyle = dateStyle
        }
        if dateFormatter.timeStyle != timeStyle {
            dateFormatter.timeStyle = timeStyle
        }

        return dateFormatter.string(from: date)
    }
}
