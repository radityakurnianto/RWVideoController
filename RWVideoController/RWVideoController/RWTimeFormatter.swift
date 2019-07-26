//
//  RWTimeFormatter.swift
//  RWVideoController
//
//  Created by Raditya Kurnianto on 7/25/19.
//  Copyright © 2019 raditya. All rights reserved.
//

import Foundation

class RWTimeFormatter {
    class func convertSecondsToReadableFormat(seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    class func getReadableFormat(currendSeconds: Int, duration: Int) -> (String, String) {
        let currentTime = RWTimeFormatter.convertSecondsToReadableFormat(seconds: currendSeconds)
        let endTime = RWTimeFormatter.convertSecondsToReadableFormat(seconds: duration)
        
        let currentHour = currentTime.0 < 10 ? "0\(currentTime.0)" : "\(currentTime.0)"
        let currentMinute = currentTime.1 < 10 ? "0\(currentTime.1)" : "\(currentTime.1)"
        let currentSecond = currentTime.2 < 10 ? "0\(currentTime.2)" : "\(currentTime.2)"
        
        let startTimeString = "\(currentHour):\(currentMinute):\(currentSecond)"
        
        let endHour = endTime.0
        let endMinute = endTime.1
        let endSecond = endTime.2
        
        let endTimeString = "\(endHour > 0 ? "\(endHour):": "")\(endMinute):\(endSecond)"
        
        return (startTimeString, endTimeString)
    }
}
