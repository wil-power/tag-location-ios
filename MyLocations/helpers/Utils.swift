//
//  Utils.swift
//  MyLocations
//
//  Created by Wilfred Asomani on 14/04/2020.
//  Copyright © 2020 Wilfred Asomani. All rights reserved.
//

import Foundation


/// run a computation after a delay in seconds
/// - Parameters:
///   - seconds: delay before excution in secods
///   - run: the code to execute
func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}
