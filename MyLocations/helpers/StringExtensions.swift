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

    /// generate a string from a placemark
    /// - Parameters:
    ///   - placemark: the target placemark
    ///   - multiline: whether the string should be 2 line, including administrative area and postal code
    /// - Returns: the generated string
    static func fromPlacemark(placemark: CLPlacemark, multiline: Bool = true) -> String {

        var line1 = ""
        line1.add(text: placemark.subThoroughfare)
        line1.add(text: placemark.thoroughfare, separatedBy: " ")
        guard multiline else {
            line1.add(text: placemark.locality, separatedBy: " ")
            return line1
        }


        var line2 = ""
        line2.add(text: placemark.locality)
        line2.add(text: placemark.administrativeArea, separatedBy: " ")
        line2.add(text: placemark.postalCode, separatedBy: " ")

        line1.add(text: line2, separatedBy: "\n")
        return line1
    }

    /// generate a string from a date
    /// - Parameters:
    ///   - date: date to generate string from
    ///   - dateStyle: style of the date
    ///   - timeStyle: style of the time
    /// - Returns: a string generated from the date in the specified style
    static func fromDate(date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {

        if dateFormatter.dateStyle != dateStyle {
            dateFormatter.dateStyle = dateStyle
        }
        if dateFormatter.timeStyle != timeStyle {
            dateFormatter.timeStyle = timeStyle
        }

        return dateFormatter.string(from: date)
    }

    /// add some text to a string
    /// - Parameters:
    ///   - text: text to add
    ///   - separatedBy: character that separates this string and the added
    mutating func add(text: String?, separatedBy: String = "") {
        guard let text = text else { return }
        if !separatedBy.isEmpty { self += separatedBy }
        self += text
    }
}
