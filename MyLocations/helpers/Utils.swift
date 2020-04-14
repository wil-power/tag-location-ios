//
//  Utils.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 14/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import Foundation

let appDocumentDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths.first!
}()
let dataSaveFailedNotification = Notification.Name(rawValue: "SaveFailedNotification")

/// run a computation after a delay in seconds
/// - Parameters:
///   - seconds: delay before excution in secods
///   - run: the code to execute
func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}

func fatalDataError(_ error: Error) {
    debugPrint("*** Fatal Error \(error)")
    // notification center here doen't refer to the iPhone's, but it's a sort of messaging between observers in this app
    NotificationCenter.default.post(name: dataSaveFailedNotification, object: nil)
}
